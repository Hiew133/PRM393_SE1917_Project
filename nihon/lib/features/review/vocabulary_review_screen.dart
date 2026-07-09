import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_config.dart';
import '../../data/models/srs_stage.dart';
import '../../data/models/vocab_card.dart';
import 'widgets/srs_rating_button.dart';
import 'widgets/vocab_flashcard.dart';
import 'widgets/vocab_session_header.dart';

/// Màn 03 – Từ vựng SRS flashcard (tab Ôn tập).
class VocabularyReviewScreen extends StatefulWidget {
  final String book;
  final int lesson;

  const VocabularyReviewScreen({
    super.key,
    required this.book,
    required this.lesson,
  });

  @override
  State<VocabularyReviewScreen> createState() => _VocabularyReviewScreenState();
}

class _VocabularyReviewScreenState extends State<VocabularyReviewScreen>
    with SingleTickerProviderStateMixin {
  late List<VocabCard> _cards = [];
  int _currentIndex = 0;
  int _sessionXp = 0;
  bool _sessionComplete = false;
  bool _isLoading = true;
  String? _error;

  late AnimationController _cardAnim;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  // Cấu hình chỉnh sửa inline chế độ Admin
  late TextEditingController _editingJpController;
  late TextEditingController _editingReadingController;
  late TextEditingController _editingViController;
  bool _isEditingCard = false;

  @override
  void initState() {
    super.initState();
    _loadCards();

    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _cardFade = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic));

    _editingJpController = TextEditingController();
    _editingReadingController = TextEditingController();
    _editingViController = TextEditingController();
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    _editingJpController.dispose();
    _editingReadingController.dispose();
    _editingViController.dispose();
    super.dispose();
  }

  void _updateControllersForCard(VocabCard card) {
    _editingJpController.text = card.word;
    _editingReadingController.text = card.reading;
    _editingViController.text = card.meaning;
  }

  /// Tải dữ liệu từ vựng từ Firebase Firestore
  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

      // Lấy từ vựng theo sách và bài học được truyền vào
      final QuerySnapshot snapshot = await firestore
          .collection('vocabulary')
          .where('book', isEqualTo: widget.book)
          .where('lesson', isEqualTo: widget.lesson)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception("Không tìm thấy từ vựng nào trên Firestore!");
      }

      final List<VocabCard> loadedCards = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final jp = data['jp'] as String? ?? '';
        final vi = data['vi'] as String? ?? '';
        
        String meaning = vi;
        String reading = data['reading'] as String? ?? jp;
        
        // Regex để tách phần hiragana trong dấu ngoặc tròn nếu có (ví dụ: "một（いち）" -> meaning: "một", reading: "いち")
        final regex = RegExp(r'[（\(]([^）\)]+)[）\)]');
        final match = regex.firstMatch(vi);
        if (match != null) {
          reading = match.group(1) ?? reading;
          meaning = vi.replaceAll(regex, '').trim();
        }

        return VocabCard(
          id: doc.id,
          word: jp,
          reading: reading,
          romaji: '', // Trình bày rỗng, sẽ hiển thị sạch đẹp
          meaning: meaning,
          exampleJp: '例文はまだありません。', 
          exampleVi: 'Chưa có ví dụ cho từ này.',
          wordTypeJp: '単語',
          wordTypeVi: 'Bài ${data['lesson'] ?? 1}',
          stage: SrsStage.apprentice1,
        );
      }).toList();

      // Đảo ngẫu nhiên danh sách để ôn tập hiệu quả hơn
      loadedCards.shuffle();

      setState(() {
        _cards = loadedCards;
        _currentIndex = 0;
        _sessionXp = 0;
        _sessionComplete = false;
        _isLoading = false;
      });
      if (loadedCards.isNotEmpty) {
        _updateControllersForCard(loadedCards[0]);
      }
      _cardAnim.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _resetSession() {
    _cards.shuffle();
    _currentIndex = 0;
    _sessionXp = 0;
    _sessionComplete = false;
    if (_cards.isNotEmpty) {
      _updateControllersForCard(_cards[0]);
    }
  }

  VocabCard? get _currentCard =>
      _currentIndex < _cards.length ? _cards[_currentIndex] : null;

  int get _reviewedCount => _sessionComplete ? _cards.length : _currentIndex;

  Future<void> _onRate(SrsRating rating) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final card = _currentCard;
    if (card == null || _sessionComplete) return;

    card.stage = rating.applyTo(card.stage);
    setState(() => _sessionXp += rating.xpReward);

    await _cardAnim.reverse();

    if (!mounted) return;

    if (_currentIndex + 1 >= _cards.length) {
      setState(() {
        _currentIndex = _cards.length;
        _sessionComplete = true;
      });
    } else {
      setState(() {
        _currentIndex++;
        _updateControllersForCard(_cards[_currentIndex]);
      });
      _cardAnim.forward(from: 0);
    }
  }

  Future<void> _confirmExit() async {
    if (_sessionComplete || AppConfig.isAdmin.value) {
      Navigator.pop(context);
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Thoát phiên ôn?', style: AppTextStyles.screenTitle),
        content: Text(
          'Tiến trình phiên này sẽ bị mất. Bạn có chắc muốn thoát?',
          style: AppTextStyles.latin(size: 14, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Ở lại',
              style: AppTextStyles.latin(weight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Thoát',
              style: AppTextStyles.latin(weight: FontWeight.w700, color: AppColors.vocab),
            ),
          ),
        ],
      ),
    );

    if (leave == true && mounted) {
      Navigator.pop(context); // Trở về màn hình chọn bài học
    }
  }

  void _goToPreviousCard() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentIndex > 0) {
      _cardAnim.reverse().then((_) {
        setState(() {
          _currentIndex--;
          _isEditingCard = false; // Reset trạng thái sửa
          _updateControllersForCard(_cards[_currentIndex]);
        });
        _cardAnim.forward(from: 0);
      });
    }
  }

  void _goToNextCard() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentIndex + 1 >= _cards.length) {
      _cardAnim.reverse().then((_) {
        setState(() {
          _currentIndex = _cards.length;
          _sessionComplete = true;
          _isEditingCard = false; // Reset trạng thái sửa
        });
      });
    } else {
      _cardAnim.reverse().then((_) {
        setState(() {
          _currentIndex++;
          _isEditingCard = false; // Reset trạng thái sửa
          _updateControllersForCard(_cards[_currentIndex]);
        });
        _cardAnim.forward(from: 0);
      });
    }
  }

  Future<void> _saveInlineEditedCard() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final card = _currentCard;
    if (card == null || card.id == null) return;

    final jp = _editingJpController.text.trim();
    final reading = _editingReadingController.text.trim();
    final vi = _editingViController.text.trim();

    if (jp.isEmpty || vi.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ Từ vựng và Ý nghĩa!')),
      );
      return;
    }

    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

      final Map<String, dynamic> updateData = {
        'jp': jp,
        'vi': vi,
      };
      if (reading.isNotEmpty) {
        updateData['reading'] = reading;
      } else {
        updateData['reading'] = FieldValue.delete();
      }

      await firestore.collection('vocabulary').doc(card.id).update(updateData);

      setState(() {
        final index = _cards.indexOf(card);
        if (index != -1) {
          final updatedCard = VocabCard(
            id: card.id,
            word: jp,
            reading: reading.isNotEmpty ? reading : jp,
            romaji: card.romaji,
            meaning: vi,
            exampleJp: card.exampleJp,
            exampleVi: card.exampleVi,
            wordTypeJp: card.wordTypeJp,
            wordTypeVi: card.wordTypeVi,
            stage: card.stage,
          );
          _cards[index] = updatedCard;
          _updateControllersForCard(updatedCard);
        }
        _isEditingCard = false;
      });

      // Đã cập nhật thành công, không hiển thị SnackBar theo yêu cầu
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật: $e')),
      );
    }
  }

  Future<void> _deleteInlineCard() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final card = _currentCard;
    if (card == null || card.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa từ vựng?'),
        content: Text('Bạn có chắc chắn muốn xóa từ vựng "${card.word}" khỏi giáo trình này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

      await firestore.collection('vocabulary').doc(card.id).delete();

      setState(() {
        _cards.remove(card);
        _isEditingCard = false;
        
        if (_cards.isEmpty) {
          _sessionComplete = true;
          _currentIndex = 0;
        } else {
          if (_currentIndex >= _cards.length) {
            _currentIndex = _cards.length - 1;
          }
          _updateControllersForCard(_cards[_currentIndex]);
        }
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $e')),
      );
    }
  }

  void _restartSession() {
    setState(_resetSession);
    _cardAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(
          color: AppColors.vocab,
        ),
      );
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải từ vựng từ Firebase',
                style: AppTextStyles.latin(size: 18, weight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.latin(size: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadCards,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vocab,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    } else if (_sessionComplete) {
      body = _SessionCompleteView(
        totalCards: _cards.length,
        sessionXp: _sessionXp,
        onRestart: _restartSession,
      );
    } else if (_cards.isEmpty) {
      body = const Center(child: Text('Không có dữ liệu từ vựng.'));
    } else {
      final card = _currentCard!;
      body = Column(
        children: [
          VocabSessionHeader(
            current: _reviewedCount + 1,
            total: _cards.length,
            sessionXp: _sessionXp,
            onBack: _confirmExit,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  _BadgeRow(card: card),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: VocabFlashcard(
                              key: ValueKey(card.word),
                              card: card,
                              isEditing: _isEditingCard,
                              jpController: _editingJpController,
                              readingController: _editingReadingController,
                              viController: _editingViController,
                              onSave: _saveInlineEditedCard,
                              onDelete: _deleteInlineCard,
                            ),
                          ),
                        ),
                        // Nút chỉnh sửa từ vựng ở góc trên bên phải nếu là Admin
                        Positioned(
                          top: 12,
                          right: 12,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: AppConfig.isAdmin,
                            builder: (context, isAdmin, child) {
                              if (!isAdmin) return const SizedBox.shrink();
                              return GestureDetector(
                                onTap: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  setState(() {
                                    _isEditingCard = !_isEditingCard;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isEditingCard
                                        ? Colors.red.withValues(alpha: 0.12)
                                        : Colors.blue.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isEditingCard
                                          ? Colors.red.withValues(alpha: 0.3)
                                          : Colors.blue.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    _isEditingCard ? Icons.close : Icons.edit,
                                    color: _isEditingCard ? Colors.red : Colors.blue,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: AppConfig.isAdmin,
                    builder: (context, isAdmin, child) {
                      if (isAdmin) {
                        return Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _currentIndex > 0 ? _goToPreviousCard : null,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.arrow_back_ios_new,
                                            size: 16,
                                            color: _currentIndex > 0 ? AppColors.vocab : AppColors.textFaint,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Trước',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _currentIndex > 0 ? AppColors.vocab : AppColors.textFaint,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.vocab,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.vocab.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _goToNextCard,
                                    borderRadius: BorderRadius.circular(16),
                                    child: const Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Tiếp theo',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            for (final rating in SrsRating.values) ...[
                              Expanded(
                                child: SrsRatingButton(
                                  rating: rating,
                                  onTap: () => _onRate(rating),
                                ),
                              ),
                              if (rating != SrsRating.easy) const SizedBox(width: 8),
                            ],
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: body,
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final VocabCard card;

  const _BadgeRow({required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: card.stage.color,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            card.stage.label,
            style: AppTextStyles.jp(size: 11, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            card.wordTypeLabel,
            style: AppTextStyles.jp(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionCompleteView extends StatelessWidget {
  final int totalCards;
  final int sessionXp;
  final VoidCallback onRestart;

  const _SessionCompleteView({
    required this.totalCards,
    required this.sessionXp,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.speaking.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🎉', style: TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 20),
          Text(
            'Hoàn thành!',
            style: AppTextStyles.latin(size: 24, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đã ôn xong $totalCards flashcard từ vựng.',
            textAlign: TextAlign.center,
            style: AppTextStyles.latin(size: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  '+$sessionXp XP',
                  style: AppTextStyles.latin(
                    size: 32,
                    weight: FontWeight.w800,
                    color: AppColors.listening,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'XP kiếm được trong phiên này',
                  style: AppTextStyles.latin(size: 12, color: AppColors.textFaint),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ôn lại'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Quay về',
                style: AppTextStyles.latin(
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

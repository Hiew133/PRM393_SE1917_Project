import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/services/vocab_progress_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_config.dart';
import '../../data/models/srs_stage.dart';
import '../../data/models/vocab_card.dart';
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

  /// Thẻ hiện tại đã được lật xem đáp án chưa (phải lật mới được trả lời).
  bool _revealed = false;

  final VocabProgressService _progress = VocabProgressService();

  /// Thứ tự doc id của phiên hiện tại — dùng để lưu/khôi phục "học đến đâu".
  List<String> _orderIds = [];

  /// Tên sách khớp với dữ liệu Firestore thực tế (sau khi thử fallback slug).
  late String _effectiveBook = _normalizedBook;

  late AnimationController _cardAnim;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  // Cấu hình chỉnh sửa inline chế độ Admin
  late TextEditingController _editingJpController;
  late TextEditingController _editingReadingController;
  late TextEditingController _editingViController;
  bool _isEditingCard = false;

  String get _normalizedBook {
    switch (widget.book) {
      case 'nhat_1':
        return 'Nhật 1';
      case 'nhat_2':
        return 'Nhật 2';
      default:
        return widget.book;
    }
  }

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

      // Lấy từ vựng theo sách và bài học được truyền vào. Một số màn hình cũ
      // truyền slug như "nhat_1", trong khi Firestore lưu "Nhật 1".
      _effectiveBook = _normalizedBook;
      QuerySnapshot snapshot = await firestore
          .collection('vocabulary')
          .where('book', isEqualTo: _normalizedBook)
          .where('lesson', isEqualTo: widget.lesson)
          .get();

      if (snapshot.docs.isEmpty && _normalizedBook != widget.book) {
        snapshot = await firestore
            .collection('vocabulary')
            .where('book', isEqualTo: widget.book)
            .where('lesson', isEqualTo: widget.lesson)
            .get();
        if (snapshot.docs.isNotEmpty) _effectiveBook = widget.book;
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
          wordTypeVi: 'Bài ${data['lesson'] ?? widget.lesson}',
          stage: SrsStage.apprentice1,
        );
      }).toList();

      // Áp cấp SRS đã lưu của user cho từng thẻ (guest: map rỗng).
      final savedStages =
          await _progress.loadCardStages(_effectiveBook, widget.lesson);
      final byId = <String, VocabCard>{
        for (final c in loadedCards)
          if (c.id != null) c.id!: c,
      };
      savedStages.forEach((id, stage) {
        byId[id]?.stage = stage;
      });

      // Khôi phục phiên dang dở nếu thứ tự đã lưu vẫn khớp bộ thẻ hiện tại;
      // nếu không thì xáo mới. Phiên mới chỉ được ghi khi trả lời thẻ đầu.
      final session =
          await _progress.loadSession(_effectiveBook, widget.lesson);
      int startIndex = 0;
      int startXp = 0;
      List<VocabCard> ordered;
      final canResume = session != null &&
          !session.done &&
          session.order.isNotEmpty &&
          session.order.length == byId.length &&
          session.order.toSet().containsAll(byId.keys);
      if (canResume) {
        ordered = [for (final id in session.order) byId[id]!];
        startIndex = session.index.clamp(0, ordered.length - 1);
        startXp = session.xp;
      } else {
        loadedCards.shuffle();
        ordered = loadedCards;
      }
      _orderIds = [
        for (final c in ordered)
          if (c.id != null) c.id!,
      ];

      if (!mounted) return;
      setState(() {
        _cards = ordered;
        _currentIndex = startIndex;
        _sessionXp = startXp;
        _sessionComplete = false;
        _revealed = false;
        _isLoading = false;
      });
      if (ordered.isNotEmpty) {
        _updateControllersForCard(ordered[startIndex]);
      }
      _cardAnim.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _resetSession() {
    _cards.shuffle();
    _orderIds = [
      for (final c in _cards)
        if (c.id != null) c.id!,
    ];
    _currentIndex = 0;
    _sessionXp = 0;
    _sessionComplete = false;
    _revealed = false;
    if (_cards.isNotEmpty) {
      _updateControllersForCard(_cards[0]);
    }
    // Ghi đè phiên cũ bằng phiên mới bắt đầu lại từ đầu.
    _progress.saveSession(
      book: _effectiveBook,
      lesson: widget.lesson,
      order: _orderIds,
      index: 0,
      xp: 0,
    );
  }

  VocabCard? get _currentCard =>
      _currentIndex < _cards.length ? _cards[_currentIndex] : null;

  int get _reviewedCount => _sessionComplete ? _cards.length : _currentIndex;

  /// Trả lời thẻ hiện tại: đúng (✓) tiến cấp SRS, sai (✗) lùi cấp.
  /// Không bắt buộc lật thẻ — thuộc rồi thì bấm ✓ đi tiếp luôn.
  /// Tiến trình được lưu ngay sau mỗi câu trả lời.
  Future<void> _onAnswer(bool correct) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final card = _currentCard;
    if (card == null || _sessionComplete) return;

    card.stage = correct ? card.stage.advance() : card.stage.regress();
    final reward = correct ? 8 : 2;
    setState(() => _sessionXp += reward);

    // Lưu cấp SRS của thẻ (fire-and-forget; guest tự bỏ qua).
    if (card.id != null) {
      _progress.saveCardResult(
        vocabId: card.id!,
        book: _effectiveBook,
        lesson: widget.lesson,
        stage: card.stage,
        correct: correct,
      );
    }

    await _cardAnim.reverse();

    if (!mounted) return;

    if (_currentIndex + 1 >= _cards.length) {
      setState(() {
        _currentIndex = _cards.length;
        _sessionComplete = true;
      });
      _progress.completeSession(
        book: _effectiveBook,
        lesson: widget.lesson,
        total: _cards.length,
        xp: _sessionXp,
      );
      // Cộng XP của cả phiên vào tiến độ chung (dashboard / streak).
      DataRepository().addXp(_sessionXp);
    } else {
      setState(() {
        _currentIndex++;
        _revealed = false;
        _updateControllersForCard(_cards[_currentIndex]);
      });
      _progress.saveSession(
        book: _effectiveBook,
        lesson: widget.lesson,
        order: _orderIds,
        index: _currentIndex,
        xp: _sessionXp,
      );
      _cardAnim.forward(from: 0);
    }
  }

  Future<void> _confirmExit() async {
    // Tài khoản đăng nhập: tiến trình đã được lưu sau mỗi câu trả lời nên
    // thoát thẳng, vào lại sẽ học tiếp từ chỗ cũ. Chỉ Guest mới mất tiến trình.
    final isGuest = RoleService().currentRole.value == AppRole.guest;
    if (_sessionComplete || AppConfig.isAdmin.value || !isGuest) {
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
      body = _EmptyVocabularyView(
        book: _normalizedBook,
        lesson: widget.lesson,
        onBack: () => Navigator.pop(context),
        onRetry: _loadCards,
      );
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
                              key: ValueKey(card.id ?? card.word),
                              card: card,
                              // Admin duyệt thẻ thì xem thẳng đáp án, không cần lật.
                              revealed: _revealed || AppConfig.isAdmin.value,
                              onFlip: () =>
                                  setState(() => _revealed = !_revealed),
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
                        // 2 nút tự đánh giá: ✗ chưa thuộc / ✓ đã thuộc.
                        // Bấm được ngay, không cần lật thẻ (lật chỉ để xem đáp án).
                        return Row(
                          children: [
                            Expanded(
                              child: _AnswerButton(
                                icon: Icons.close_rounded,
                                label: 'Chưa thuộc',
                                color: const Color(0xFFDC2626),
                                background: const Color(0xFFFEE2E2),
                                borderColor: const Color(0xFFFECACA),
                                onTap: () => _onAnswer(false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AnswerButton(
                                icon: Icons.check_rounded,
                                label: 'Đã thuộc',
                                color: const Color(0xFF16A34A),
                                background: const Color(0xFFF0FDF4),
                                borderColor: const Color(0xFFBBF7D0),
                                onTap: () => _onAnswer(true),
                              ),
                            ),
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

/// Nút trả lời ✗/✓.
class _AnswerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final Color borderColor;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.latin(
                  size: 15,
                  weight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
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

class _EmptyVocabularyView extends StatelessWidget {
  final String book;
  final int lesson;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _EmptyVocabularyView({
    required this.book,
    required this.lesson,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined, color: AppColors.vocab, size: 48),
          const SizedBox(height: 16),
          Text(
            'Chưa có từ vựng',
            style: AppTextStyles.latin(size: 18, weight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$book - Bài $lesson hiện chưa có từ vựng trên Firestore.',
            textAlign: TextAlign.center,
            style: AppTextStyles.latin(size: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vocab,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
        ],
      ),
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
                  'XP đã được cộng vào tiến độ của bạn',
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

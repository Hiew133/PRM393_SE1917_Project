import 'package:flutter/material.dart';
import '../../core/services/data_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/srs_card.dart';
import '../../data/models/srs_stage.dart';
import 'widgets/srs_rating_button.dart';

class KanjiReviewScreen extends StatefulWidget {
  const KanjiReviewScreen({super.key});

  @override
  State<KanjiReviewScreen> createState() => _KanjiReviewScreenState();
}

class _KanjiReviewScreenState extends State<KanjiReviewScreen>
    with SingleTickerProviderStateMixin {
  final DataRepository _repository = DataRepository();
  late List<CardProgress> _reviewQueue = [];
  int _currentIndex = 0;
  bool _sessionComplete = false;
  bool _isFlipped = false;
  bool _reviewAllMode = false;

  late AnimationController _cardAnim;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _buildQueue();

    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _cardFade = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic));

    _cardAnim.forward();
  }

  @override
  void dispose() {
    _cardAnim.dispose();
    super.dispose();
  }

  void _buildQueue() {
    final now = DateTime.now();
    // Filter cards to only Kanji
    final allKanjiCards = _repository.srsCards
        .where((c) =>
            c.card.category.contains('Kanji') ||
            c.card.category.contains('Hán tự'))
        .toList();

    // Default: load due cards
    final dueCards = allKanjiCards
        .where((card) => !card.nextReview.isAfter(now))
        .toList();

    if (dueCards.isNotEmpty) {
      _reviewQueue = dueCards;
      _reviewAllMode = false;
    } else {
      _reviewQueue = [];
      _reviewAllMode = false;
    }
    _reviewQueue.shuffle();
    _currentIndex = 0;
    _sessionComplete = false;
    _isFlipped = false;
  }

  void _startReviewAll() {
    final allKanjiCards = _repository.srsCards
        .where((c) =>
            c.card.category.contains('Kanji') ||
            c.card.category.contains('Hán tự'))
        .toList();

    setState(() {
      _reviewQueue = List.from(allKanjiCards)..shuffle();
      _reviewAllMode = true;
      _currentIndex = 0;
      _sessionComplete = false;
      _isFlipped = false;
    });
    _cardAnim.forward(from: 0);
  }

  CardProgress? get _currentCard =>
      _currentIndex < _reviewQueue.length ? _reviewQueue[_currentIndex] : null;

  SrsStage _srsStageFromString(String stage) {
    switch (stage) {
      case '見習い I':
        return SrsStage.apprentice1;
      case '見習い II':
        return SrsStage.apprentice2;
      case '見習い III':
        return SrsStage.apprentice3;
      case '見習い IV':
        return SrsStage.apprentice4;
      case '弟子 I':
        return SrsStage.guru1;
      case '弟子 II':
        return SrsStage.guru2;
      case '達人':
        return SrsStage.master;
      case '悟り':
        return SrsStage.enlightened;
      case '燃焼':
      case '燃焼済':
        return SrsStage.burned;
      default:
        return SrsStage.apprentice1;
    }
  }

  String _stringFromSrsStage(SrsStage stage) {
    switch (stage) {
      case SrsStage.apprentice1:
        return '見習い I';
      case SrsStage.apprentice2:
        return '見習い II';
      case SrsStage.apprentice3:
        return '見習い III';
      case SrsStage.apprentice4:
        return '見習い IV';
      case SrsStage.guru1:
        return '弟子 I';
      case SrsStage.guru2:
        return '弟子 II';
      case SrsStage.master:
        return '達人';
      case SrsStage.enlightened:
        return '悟り';
      case SrsStage.burned:
        return '燃焼';
    }
  }

  DateTime _nextReviewFromRating(SrsRating rating) {
    final now = DateTime.now();
    switch (rating) {
      case SrsRating.again:
        return now.add(const Duration(hours: 1));
      case SrsRating.hard:
        return now.add(const Duration(days: 1));
      case SrsRating.good:
        return now.add(const Duration(days: 4));
      case SrsRating.easy:
        return now.add(const Duration(days: 7));
    }
  }

  Future<void> _onRate(SrsRating rating) async {
    final currentProgress = _currentCard;
    if (currentProgress == null || _sessionComplete) return;

    // 1. Calculate new SRS Stage & next review interval
    final currentStage = _srsStageFromString(currentProgress.srsStage);
    final newStage = rating.applyTo(currentStage);
    final nextReview = _nextReviewFromRating(rating);

    // 2. Build updated progress
    final updatedProgress = CardProgress(
      card: currentProgress.card,
      srsStage: _stringFromSrsStage(newStage),
      nextReview: nextReview,
    );

    // 3. Update in local repository list
    final repoIndex = _repository.srsCards.indexWhere(
        (c) => c.card.word == currentProgress.card.word);
    if (repoIndex != -1) {
      _repository.srsCards[repoIndex] = updatedProgress;
    } else {
      _repository.srsCards.add(updatedProgress);
    }

    // 4. Trigger repo save & Firestore sync
    _repository.notifyReviewStateChanged();

    await _cardAnim.reverse();

    if (!mounted) return;

    if (_currentIndex + 1 >= _reviewQueue.length) {
      setState(() {
        _currentIndex = _reviewQueue.length;
        _sessionComplete = true;
      });
    } else {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
      _cardAnim.forward(from: 0);
    }
  }

  Future<void> _confirmExit() async {
    if (_sessionComplete) {
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
              style: AppTextStyles.latin(
                  weight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Thoát',
              style: AppTextStyles.latin(
                  weight: FontWeight.w700, color: AppColors.vocab),
            ),
          ),
        ],
      ),
    );

    if (leave == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _reviewQueue.isNotEmpty
        ? (_sessionComplete
            ? 1.0
            : _currentIndex / _reviewQueue.length)
        : 0.0;

    Widget body;

    if (_reviewQueue.isEmpty) {
      body = _EmptyKanjiReviewView(
        onBack: () => Navigator.pop(context),
        onReviewAll: _startReviewAll,
      );
    } else if (_sessionComplete) {
      body = _SessionCompleteView(
        totalCards: _reviewQueue.length,
        onBack: () => Navigator.pop(context),
      );
    } else {
      final cardProgress = _currentCard!;
      body = Column(
        children: [
          // Custom Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Material(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _confirmExit,
                        borderRadius: BorderRadius.circular(10),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.chevron_left,
                              size: 22, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.kanji,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                _reviewAllMode
                                    ? '漢字 · Ôn tập tất cả'
                                    : '漢字 · SRS Ôn tập Kanji',
                                style: AppTextStyles.latin(
                                  size: 15,
                                  weight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${_currentIndex + 1} / ${_reviewQueue.length} chữ Kanji',
                            style: AppTextStyles.latin(
                                size: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        Container(color: AppColors.border),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.kanji, AppColors.brand],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: _srsStageFromString(cardProgress.srsStage)
                              .color,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          _srsStageFromString(cardProgress.srsStage).label,
                          style: AppTextStyles.jp(
                              size: 11,
                              weight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          cardProgress.card.category,
                          style: AppTextStyles.jp(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: _KanjiFlashcard(
                          card: cardProgress.card,
                          isFlipped: _isFlipped,
                          onTap: () {
                            setState(() {
                              _isFlipped = !_isFlipped;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isFlipped)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kanji,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFlipped = true;
                          });
                        },
                        child: Text(
                          'Lật thẻ để xem cách đọc & nghĩa',
                          style: AppTextStyles.latin(
                            size: 16,
                            weight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        for (final rating in SrsRating.values) ...[
                          Expanded(
                            child: SrsRatingButton(
                              rating: rating,
                              onTap: () => _onRate(rating),
                            ),
                          ),
                          if (rating != SrsRating.easy)
                            const SizedBox(width: 8),
                        ],
                      ],
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

class _KanjiFlashcard extends StatelessWidget {
  final SrsCard card;
  final bool isFlipped;
  final VoidCallback onTap;

  const _KanjiFlashcard({
    required this.card,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A2D1F0E),
              blurRadius: 32,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Color(0x0D2D1F0E),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            if (!isFlipped) ...[
              // Front side
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  card.word,
                  style: AppTextStyles.jp(
                    size: 96,
                    weight: FontWeight.w700,
                    height: 1.05,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              Text(
                'Chạm để lật thẻ 🔄',
                style: AppTextStyles.latin(
                  size: 13,
                  color: AppColors.textMuted,
                ).copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              // Back side
              Text(
                card.furigana, // Readings (Onyomi / Kunyomi)
                style: AppTextStyles.jp(
                  size: 20,
                  weight: FontWeight.w500,
                  color: AppColors.kanji,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  card.word,
                  style: AppTextStyles.jp(
                    size: 64,
                    weight: FontWeight.w700,
                    height: 1.05,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.romaji, // Han-Viet representation
                style: AppTextStyles.latin(
                  size: 16,
                  weight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 50,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                card.meaning, // Vietnamese meaning
                style: AppTextStyles.latin(
                  size: 24,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (card.exampleJa.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ví dụ:',
                        style: AppTextStyles.latin(
                          size: 12,
                          weight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card.exampleJa,
                        style: AppTextStyles.jp(
                          size: 14,
                          weight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.exampleVi,
                        style: AppTextStyles.latin(
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _EmptyKanjiReviewView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onReviewAll;

  const _EmptyKanjiReviewView({
    required this.onBack,
    required this.onReviewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.speaking, size: 64),
          const SizedBox(height: 20),
          Text(
            'Không có thẻ đến hạn!',
            style: AppTextStyles.latin(size: 20, weight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tuyệt vời! Bạn đã hoàn thành tất cả các thẻ ôn tập Kanji của hôm nay.',
            textAlign: TextAlign.center,
            style: AppTextStyles.latin(size: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onReviewAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kanji,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ôn tập lại tất cả Kanji'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Quay về trang chủ',
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
  final VoidCallback onBack;

  const _SessionCompleteView({
    required this.totalCards,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Text('🌸', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Hoàn thành phiên ôn!',
            style: AppTextStyles.latin(size: 24, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đã hoàn thành xuất sắc việc ôn tập $totalCards chữ Kanji hôm nay.',
            textAlign: TextAlign.center,
            style: AppTextStyles.latin(
              size: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kanji,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Text(
                'Tiếp tục',
                style: AppTextStyles.latin(size: 16, weight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

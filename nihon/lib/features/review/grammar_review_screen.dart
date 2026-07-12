import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/services/data_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../lessons/kanji_data.dart';

class GrammarReviewScreen extends StatefulWidget {
  const GrammarReviewScreen({super.key});

  @override
  State<GrammarReviewScreen> createState() => _GrammarReviewScreenState();
}

class _GrammarReviewScreenState extends State<GrammarReviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  late List<GrammarPoint> _queue;
  int _index = 0;
  int _xp = 0;
  bool _isFlipped = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _queue = List<GrammarPoint>.from(DataRepository().grammarPoints);
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _next() {
    if (_queue.isEmpty) return;
    setState(() {
      _xp += 4;
      if (_index < _queue.length - 1) {
        _index++;
        _isFlipped = false;
        _flipController.reset();
      } else {
        _done = true;
      }
    });
  }

  void _restart() {
    setState(() {
      _queue = List<GrammarPoint>.from(DataRepository().grammarPoints);
      _index = 0;
      _xp = 0;
      _isFlipped = false;
      _done = false;
      _flipController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => Navigator.pop(context)),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Chưa có mẫu ngữ pháp nào để ôn tập.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.latin(
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_done) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.reading.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.rule_rounded,
                    color: AppColors.reading,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hoàn thành!',
                  style: AppTextStyles.latin(
                    size: 24,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn đã ôn xong ${_queue.length} mẫu ngữ pháp.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.latin(
                    size: 14,
                    color: AppColors.textMuted,
                  ),
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
                        '+$_xp XP',
                        style: AppTextStyles.latin(
                          size: 32,
                          weight: FontWeight.w800,
                          color: AppColors.listening,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'XP kiếm được trong phiên này',
                        style: AppTextStyles.latin(
                          size: 12,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _restart,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      side: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
          ),
        ),
      );
    }

    final current = _queue[_index];
    final progress = (_index + 1) / _queue.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.pop(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  color: AppColors.reading,
                  backgroundColor: AppColors.border,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Text(
                    '${_index + 1}/${_queue.length}',
                    style: AppTextStyles.latin(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '+$_xp XP',
                    style: AppTextStyles.latin(
                      size: 12,
                      weight: FontWeight.w800,
                      color: AppColors.listening,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * math.pi;
                    final showBack = angle > math.pi / 2;
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: showBack
                          ? Transform(
                              transform: Matrix4.identity()..rotateY(math.pi),
                              alignment: Alignment.center,
                              child: _GrammarCard(
                                grammarPoint: current,
                                isBackSide: true,
                              ),
                            )
                          : _GrammarCard(
                              grammarPoint: current,
                              isBackSide: false,
                            ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _isFlipped
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.reading,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _next,
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        _index == _queue.length - 1
                            ? 'HOÀN THÀNH'
                            : 'TIẾP TỤC',
                        style: AppTextStyles.latin(
                          size: 15,
                          weight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _flipCard,
                      child: Text(
                        'LẬT THẺ',
                        style: AppTextStyles.latin(
                          size: 15,
                          weight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Ngữ pháp',
                      style: AppTextStyles.latin(
                        size: 16,
                        color: AppColors.textPrimary,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '文法',
                      style: AppTextStyles.jp(
                        size: 17,
                        color: AppColors.reading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Ôn mẫu câu bằng thẻ lật',
                  style: AppTextStyles.latin(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarCard extends StatelessWidget {
  const _GrammarCard({
    required this.grammarPoint,
    required this.isBackSide,
  });

  final GrammarPoint grammarPoint;
  final bool isBackSide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '文法',
                    style: AppTextStyles.jp(
                      size: 11,
                      color: AppColors.kanji,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    grammarPoint.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.latin(
                      size: 22,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    grammarPoint.subTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.latin(
                      size: 14,
                      color: AppColors.textSecondary,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD88A)),
                    ),
                    child: Text(
                      grammarPoint.pattern,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.jp(
                        size: 18,
                        color: AppColors.brandDark,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isBackSide)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(
                    height: 28,
                    color: AppColors.border,
                    thickness: 1.2,
                  ),
                  if (grammarPoint.note.isNotEmpty) ...[
                    Text(
                      grammarPoint.note,
                      style: AppTextStyles.latin(
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (grammarPoint.examples.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grammarPoint.examples.first.exampleJa,
                            style: AppTextStyles.jp(
                              size: 14,
                              color: AppColors.textPrimary,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            grammarPoint.examples.first.exampleVi,
                            style: AppTextStyles.latin(
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            else
              const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

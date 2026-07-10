import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Header phiên ôn từ vựng – back, tiêu đề, XP, progress bar.
class VocabSessionHeader extends StatelessWidget {
  final int current;
  final int total;
  final int sessionXp;
  final VoidCallback? onBack;

  const VocabSessionHeader({
    super.key,
    required this.current,
    required this.total,
    required this.sessionXp,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _BackButton(onTap: onBack),
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
                            color: AppColors.vocab,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '語彙 · SRS 復習',
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
                      '$current / $total flashcard',
                      style: AppTextStyles.latin(size: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD88A)),
                ),
                child: Text(
                  '+$sessionXp XP',
                  style: AppTextStyles.latin(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.listening,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          VocabProgressBar(progress: progress),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _BackButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.chevron_left, size: 22, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Gradient progress bar overlay – dùng ShaderMask cho gradient vocab→brand.
class VocabProgressBar extends StatelessWidget {
  final double progress;

  const VocabProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
                    colors: [AppColors.vocab, AppColors.brand],
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

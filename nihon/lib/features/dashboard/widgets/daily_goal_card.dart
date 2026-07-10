import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Thẻ "Mục tiêu hôm nay" với thanh tiến trình XP.
class DailyGoalCard extends StatelessWidget {
  final int current;
  final int target;

  const DailyGoalCard({super.key, required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    final remaining = (target - current).clamp(0, target);
    final progress = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MỤC TIÊU HÔM NAY', style: AppTextStyles.overline),
                  const SizedBox(height: 3),
                  Text(
                    '$current / $target XP',
                    style: AppTextStyles.latin(
                      size: 16,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceAlt,
                ),
                alignment: Alignment.center,
                child: const Text('⭐', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.brand),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Còn $remaining XP để đạt mục tiêu hôm nay',
            style: AppTextStyles.latin(size: 11, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}
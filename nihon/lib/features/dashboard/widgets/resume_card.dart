import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Thẻ "Tiếp tục học" (nền tối với gradient).
class ResumeCard extends StatelessWidget {
  const ResumeCard({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: AppColors.resumeCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIẾP TỤC HỌC',
            style: AppTextStyles.latin(
              size: 10,
              weight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '語彙 · Bài 12',
            style: AppTextStyles.jp(size: 17, color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(
            'Thức ăn và đồ uống · 8 từ cần ôn',
            style: AppTextStyles.latin(
              size: 13,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onContinue,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tiếp tục',
                    style: AppTextStyles.latin(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('→', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
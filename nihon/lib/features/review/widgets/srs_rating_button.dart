import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/srs_stage.dart';

/// Nút đánh giá SRS (Lại / Khó / Tốt / Dễ).
class SrsRatingButton extends StatelessWidget {
  final SrsRating rating;
  final VoidCallback onTap;

  const SrsRatingButton({
    super.key,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: rating.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rating.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(rating.emoji, style: const TextStyle(fontSize: 18, height: 1)),
                const SizedBox(height: 3),
                Text(
                  rating.label,
                  style: AppTextStyles.latin(
                    size: 11,
                    weight: FontWeight.w700,
                    color: rating.textColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  rating.interval,
                  style: AppTextStyles.latin(size: 10, color: AppColors.textFaint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

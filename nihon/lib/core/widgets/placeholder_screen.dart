import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Màn tạm cho các tính năng chưa dựng – dùng làm base.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String jpTitle;
  final IconData icon;
  final Color color;
  final String description;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.jpTitle,
    required this.icon,
    required this.color,
    this.description = 'Màn hình đang được xây dựng.',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(jpTitle, style: AppTextStyles.jp(size: 24, color: color)),
          Text(title, style: AppTextStyles.screenTitle),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(icon, size: 44, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.latin(
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
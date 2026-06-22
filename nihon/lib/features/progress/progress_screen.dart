import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/placeholder_screen.dart';

/// Màn "Tiến độ" – streak, biểu đồ học tập, huy hiệu.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Tiến độ',
      jpTitle: '進捗',
      icon: Icons.bar_chart,
      color: AppColors.reading,
      description: 'Theo dõi streak, XP và biểu đồ tiến độ học tập.',
    );
  }
}

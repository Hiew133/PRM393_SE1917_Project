import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/placeholder_screen.dart';

/// Màn "Bài học" – danh sách bài học theo lộ trình JLPT.
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Bài học',
      jpTitle: 'レッスン',
      icon: Icons.menu_book,
      color: AppColors.brand,
      description: 'Danh sách bài học theo lộ trình JLPT N5 → N1.',
    );
  }
}
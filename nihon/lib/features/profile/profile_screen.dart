import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/placeholder_screen.dart';

/// Màn "Cá nhân" – hồ sơ, cài đặt, lộ trình JLPT.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Cá nhân',
      jpTitle: 'プロフィール',
      icon: Icons.person,
      color: AppColors.kanji,
      description: 'Hồ sơ người dùng, cài đặt và mục tiêu học tập.',
    );
  }
}
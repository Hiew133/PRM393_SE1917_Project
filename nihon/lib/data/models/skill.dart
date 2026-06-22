import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Một kỹ năng học (Từ vựng, Kanji, Đọc, Nghe, Nói...).
class Skill {
  final String jpLabel; // 語彙, 漢字...
  final String viLabel; // Từ vựng, Kanji...
  final Color color;
  final String progressText; // "234 từ đã học"
  final double progress; // 0.0 → 1.0

  const Skill({
    required this.jpLabel,
    required this.viLabel,
    required this.color,
    required this.progressText,
    required this.progress,
  });
}

/// Dữ liệu mẫu – sau này thay bằng dữ liệu thật từ backend/local DB.
const List<Skill> kSampleSkills = [
  Skill(
    jpLabel: '語彙',
    viLabel: 'Từ vựng',
    color: AppColors.vocab,
    progressText: '234 từ đã học',
    progress: 0.48,
  ),
  Skill(
    jpLabel: '漢字',
    viLabel: 'Kanji',
    color: AppColors.kanji,
    progressText: '89 chữ đã học',
    progress: 0.30,
  ),
  Skill(
    jpLabel: '読む',
    viLabel: 'Đọc hiểu',
    color: AppColors.reading,
    progressText: '47 bài',
    progress: 0.22,
  ),
  Skill(
    jpLabel: '聴く',
    viLabel: 'Nghe',
    color: AppColors.listening,
    progressText: '23 bài',
    progress: 0.18,
  ),
  Skill(
    jpLabel: '話す',
    viLabel: 'Luyện nói',
    color: AppColors.speaking,
    progressText: '23 bài hoàn thành',
    progress: 0.38,
  ),
];

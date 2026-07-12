import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Một kỹ năng học (Từ vựng, Kanji, Đọc, Nghe, Nói...).
class Skill {
  final String jpLabel; // 語彙, 漢字...
  final String viLabel; // Từ vựng, Kanji...
  final Color color;

  const Skill({
    required this.jpLabel,
    required this.viLabel,
    required this.color,
  });
}

/// Danh sách kỹ năng hiển thị trên Trang chủ.
const List<Skill> kSampleSkills = [
  Skill(
    jpLabel: '語彙',
    viLabel: 'Từ vựng',
    color: AppColors.vocab,
  ),
  Skill(
    jpLabel: '漢字',
    viLabel: 'Kanji',
    color: AppColors.kanji,
  ),
  Skill(
    jpLabel: '文法',
    viLabel: 'Ngữ pháp',
    color: AppColors.reading,
  ),
  Skill(
    jpLabel: '聴く',
    viLabel: 'Nghe',
    color: AppColors.listening,
  ),
  Skill(
    jpLabel: '話す',
    viLabel: 'Luyện nói',
    color: AppColors.speaking,
  ),
];

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'grammar_lessons_screen.dart';
import 'topic_content.dart';
import 'topic_detail_screen.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  void _openTopic(BuildContext context, TopicContent topic, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicDetailScreen(topic: topic, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bài học', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Chọn kỹ năng',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Luyện tập các kỹ năng tiếng Nhật theo lộ trình.',
            style: TextStyle(fontSize: 15, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // Ngữ pháp
          _LessonBar(
            title: 'Ngữ pháp',
            subtitle: 'Học các cấu trúc ngữ pháp tiếng Nhật',
            icon: Icons.format_list_bulleted_rounded,
            iconColor: AppColors.reading,
            iconBg: const Color(0xFFE6FFFA),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GrammarLessonsScreen()),
            ),
          ),

          const SizedBox(height: 24),
          Text('Chủ đề', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 12),

          _LessonBar(
            title: 'Kinh tế',
            subtitle: '経済 · Từ vựng & bài đọc chủ đề kinh tế',
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.listening,
            iconBg: const Color(0xFFFFF1E0),
            onTap: () => _openTopic(context, kEconomyTopic, AppColors.listening),
          ),
          const SizedBox(height: 12),
          _LessonBar(
            title: 'Chính trị',
            subtitle: '政治 · Từ vựng & bài đọc chủ đề chính trị',
            icon: Icons.account_balance_rounded,
            iconColor: AppColors.kanji,
            iconBg: const Color(0xFFF3E8FF),
            onTap: () => _openTopic(context, kPoliticsTopic, AppColors.kanji),
          ),
          const SizedBox(height: 12),
          _LessonBar(
            title: 'Văn hoá',
            subtitle: '文化 · Từ vựng & bài đọc chủ đề văn hoá',
            icon: Icons.temple_buddhist_rounded,
            iconColor: AppColors.vocab,
            iconBg: const Color(0xFFFFE9E5),
            onTap: () => _openTopic(context, kCultureTopic, AppColors.vocab),
          ),
        ],
      ),
    );
  }
}

/// Một "thanh" bài học full-width (icon tròn + tiêu đề + mô tả + mũi tên).
class _LessonBar extends StatelessWidget {
  const _LessonBar({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: iconBg,
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

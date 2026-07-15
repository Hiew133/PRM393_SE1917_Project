import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'topic_content.dart';

/// Hiển thị nội dung một chủ đề: từ vựng + các bài đọc ngắn có dịch.
class TopicDetailScreen extends StatelessWidget {
  const TopicDetailScreen({super.key, required this.topic, required this.color});

  final TopicContent topic;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          topic.titleVi,
          style: AppTextStyles.latin(size: 20, weight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.titleJp, style: AppTextStyles.jp(size: 34, weight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text('${topic.vocab.length} từ vựng · ${topic.readings.length} bài đọc',
                    style: AppTextStyles.latin(size: 13, color: AppColors.textMuted, weight: FontWeight.w600)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Từ vựng', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < topic.vocab.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _vocabRow(topic.vocab[i]),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Bài đọc', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 10),
          for (final r in topic.readings) ...[
            _readingCard(r),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _vocabRow(TopicVocab v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.reading, style: AppTextStyles.jp(size: 12, color: AppColors.textMuted)),
                Text(v.word, style: AppTextStyles.jp(size: 20, weight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Flexible(
            child: Text(
              v.meaning,
              textAlign: TextAlign.right,
              style: AppTextStyles.latin(size: 14, weight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readingCard(TopicReading r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.jp,
            style: AppTextStyles.jp(size: 17, height: 1.7, weight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Text(
            r.vi,
            style: AppTextStyles.latin(size: 13.5, height: 1.6, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

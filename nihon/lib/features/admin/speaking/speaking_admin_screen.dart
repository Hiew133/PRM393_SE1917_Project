import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'data/admin_repository.dart';
import 'exam_list_screen.dart';

/// Hub quản lý phần NÓI (話す) trong Admin — chọn chuẩn đề: JPD316 / JPD113.
/// Vào từ thẻ 話す ở [AdminHomeScreen].
class SpeakingAdminScreen extends StatelessWidget {
  const SpeakingAdminScreen({super.key});

  void _openList(BuildContext context, int tab) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExamListScreen(initialTab: tab),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: repo,
          builder: (context, _) {
            final jpd316 = repo.exams.length;
            final nihon1 = repo.nihon1Exams.length;
            final nihon1Pub = repo.publishedNihon1Exams.length;
            final nihon2 = repo.nihon2Exams.length;
            final nihon2Pub = repo.publishedNihon2Exams.length;
            return Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      Text('Chọn chuẩn đề để quản lý',
                          style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 4),
                      Text('Mỗi chuẩn thi có cấu trúc đề riêng.',
                          style: AppTextStyles.latin(
                              size: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      _StandardCard(
                        emoji: '🟣',
                        jp: '会話',
                        color: AppColors.kanji,
                        title: 'Đề thi nói Nhật 3 · JPD316',
                        subtitle:
                            'Soạn hội thoại 会話 + câu hỏi Q&A (có tranh/không/tự do)',
                        stat: '$jpd316 đề',
                        onTap: () => _openList(context, 0),
                      ),
                      const SizedBox(height: 12),
                      _StandardCard(
                        emoji: '🟢',
                        jp: '日本語１',
                        color: AppColors.speaking,
                        title: 'Đề thi nói Nhật 1 · JPD113',
                        subtitle:
                            'Soạn bài đọc + tranh + câu hỏi theo tranh + câu tự do',
                        stat: '$nihon1 đề · $nihon1Pub xuất bản',
                        onTap: () => _openList(context, 1),
                      ),
                      const SizedBox(height: 12),
                      _StandardCard(
                        emoji: '🔵',
                        jp: '日本語２',
                        color: AppColors.srsMaster,
                        title: 'Đề thi nói Nhật 2 · JPD123',
                        subtitle:
                            'Soạn bài đọc + tranh + 1 câu theo tranh + 2 câu tự do',
                        stat: '$nihon2 đề · $nihon2Pub xuất bản',
                        onTap: () => _openList(context, 2),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10)),
              child:
                  const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Quản lý phần Nói',
                        style: AppTextStyles.latin(
                            size: 19, weight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('話す',
                        style: AppTextStyles.jp(
                            size: 17, color: AppColors.speaking)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Soạn đề thi Nói',
                    style: AppTextStyles.latin(
                        size: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardCard extends StatelessWidget {
  final String emoji;
  final String jp;
  final Color color;
  final String title;
  final String subtitle;
  final String stat;
  final VoidCallback onTap;
  const _StandardCard({
    required this.emoji,
    required this.jp,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.stat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45)),
            color: color.withValues(alpha: 0.06),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(jp,
                            style: AppTextStyles.jp(
                                size: 14,
                                weight: FontWeight.w700,
                                color: color)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(stat,
                              style: AppTextStyles.latin(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(title,
                        style: AppTextStyles.latin(
                            size: 15, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: AppTextStyles.latin(
                            size: 12,
                            height: 1.35,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

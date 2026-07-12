import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'kanji_data.dart';
import 'kanji_study_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final LessonData lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
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
          lesson.title,
          style: AppTextStyles.latin(size: 16, color: AppColors.textPrimary, weight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Thông tin mô tả bài học
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCD88A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.jpTitle,
                    style: AppTextStyles.jp(size: 14, color: AppColors.brandDark, weight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.description,
                    style: AppTextStyles.latin(size: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Danh sách chữ Hán (${lesson.kanjis.length})',
              style: AppTextStyles.latin(size: 14, color: AppColors.textMuted, weight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: lesson.kanjis.length,
                itemBuilder: (context, index) {
                  final kanji = lesson.kanjis[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KanjiStudyScreen(
                            kanji: kanji,
                            index: index,
                            totalCount: lesson.kanjis.length,
                            lessonTitle: lesson.title,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            kanji.character,
                            style: AppTextStyles.jp(size: 32, color: AppColors.textPrimary, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            kanji.hanViet,
                            style: AppTextStyles.latin(size: 12, color: AppColors.kanji, weight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            kanji.meaning,
                            style: AppTextStyles.latin(size: 10, color: AppColors.textFaint),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

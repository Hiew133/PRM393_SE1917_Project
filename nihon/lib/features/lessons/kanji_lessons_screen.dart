import 'package:flutter/material.dart';
import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/guest_lock_dialog.dart';
import 'kanji_data.dart';
import 'lesson_detail_screen.dart';

class KanjiLessonsScreen extends StatelessWidget {
  const KanjiLessonsScreen({super.key});

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
          'Lộ trình Kanji',
          style: AppTextStyles.latin(size: 20, weight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: ValueListenableBuilder<List<LessonData>>(
        valueListenable: DataRepository().lessonsNotifier,
        builder: (context, lessonsList, child) {
          if (lessonsList.isEmpty) {
            return Center(
              child: Text(
                'Chưa có bài học nào.\nHãy thêm bài học mới ở mục Quản lý!',
                textAlign: TextAlign.center,
                style: AppTextStyles.latin(size: 14, color: AppColors.textMuted),
              ),
            );
          }
          return ValueListenableBuilder<AppRole>(
            valueListenable: RoleService().currentRole,
            builder: (context, currentRole, child) {
              final isGuest = currentRole == AppRole.guest;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: lessonsList.length,
                itemBuilder: (context, index) {
                  final lesson = lessonsList[index];
                  final kanjiCharacters = lesson.kanjis.map((k) => k.character).join(', ');
                  final isLocked = isGuest && index > 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isLocked ? AppColors.surface.withOpacity(0.7) : AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        const BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.015),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          if (isLocked) {
                            showGuestLockDialog(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LessonDetailScreen(lesson: lesson),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isLocked ? Colors.grey.shade200 : AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isLocked ? Colors.grey.shade300 : const Color(0xFFFCD88A)),
                                    ),
                                    alignment: Alignment.center,
                                    child: isLocked
                                        ? const Icon(Icons.lock_outline, color: AppColors.textFaint, size: 20)
                                        : Text(
                                            '課 ${index + 1}',
                                            style: AppTextStyles.jp(
                                              size: 14,
                                              color: AppColors.brandDark,
                                              weight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lesson.title + (isLocked ? ' 🔒' : ''),
                                          style: AppTextStyles.latin(
                                            size: 15,
                                            weight: FontWeight.bold,
                                            color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lesson.jpTitle,
                                          style: AppTextStyles.jp(
                                            size: 12,
                                            color: AppColors.textFaint,
                                            weight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                isLocked ? 'Đăng nhập tài khoản để mở khóa nội dung bài học này.' : lesson.description,
                                style: AppTextStyles.latin(size: 13, color: isLocked ? AppColors.textFaint : AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.border, thickness: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.bookmark_outline_rounded, color: isLocked ? AppColors.textFaint : AppColors.kanji, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isLocked ? 'Chữ Hán tự: Bị giới hạn' : 'Các chữ học: $kanjiCharacters',
                                      style: AppTextStyles.jp(
                                        size: 12,
                                        color: isLocked ? AppColors.textFaint : AppColors.kanji,
                                        weight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(isLocked ? Icons.lock_outline : Icons.chevron_right_rounded, color: AppColors.textFaint, size: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

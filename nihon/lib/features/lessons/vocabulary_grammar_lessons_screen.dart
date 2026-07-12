import 'package:flutter/material.dart';

import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/auth_screen.dart';
import 'kanji_data.dart';
import 'lesson_detail_screen.dart';

/// Màn "Vocabulary & Grammar" – hiển thị lộ trình bài học Kanji theo giáo trình PDF.
class VocabularyGrammarLessonsScreen extends StatelessWidget {
  const VocabularyGrammarLessonsScreen({super.key});

  void _showGuestLockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.vocab, size: 28),
            const SizedBox(width: 10),
            Text(
              'Tính năng giới hạn',
              style: AppTextStyles.latin(size: 18, weight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Bạn đang sử dụng chế độ Khách. Vui lòng đăng ký hoặc đăng nhập tài khoản để học đầy đủ tất cả các bài học và lưu tiến trình học tập!',
          style: AppTextStyles.latin(size: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Để sau',
              style: AppTextStyles.latin(size: 14, color: AppColors.textMuted, weight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen(startRegister: false)),
              );
            },
            child: const Text('Đăng nhập ngay'),
          ),
        ],
      ),
    );
  }

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
          'Lộ trình Bài học',
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

              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD4C8BC)),
                      ),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: const Color(0xFFFCEAD2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5D5C5)),
                        ),
                        labelColor: const Color(0xFFC0701C),
                        unselectedLabelColor: const Color(0xFF7A6E65),
                        labelStyle: AppTextStyles.latin(size: 14, weight: FontWeight.bold),
                        unselectedLabelStyle: AppTextStyles.latin(size: 14, weight: FontWeight.bold),
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Từ vựng'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.format_list_bulleted_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Ngữ pháp'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          ListView.builder(
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
                                        _showGuestLockDialog(context);
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
                          ),
                          ValueListenableBuilder<List<GrammarPoint>>(
                            valueListenable: DataRepository().grammarPointsNotifier,
                            builder: (context, grammarPoints, child) {
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: grammarPoints.length,
                                itemBuilder: (context, index) {
                                  final grammarPoint = grammarPoints[index];
                                  final isLocked = isGuest && index >= 2;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: isLocked ? AppColors.surface.withOpacity(0.7) : AppColors.surface,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: AppColors.border),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color.fromRGBO(0, 0, 0, 0.015),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: isLocked
                                        ? InkWell(
                                            onTap: () => _showGuestLockDialog(context),
                                            borderRadius: BorderRadius.circular(24),
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          grammarPoint.title + ' 🔒',
                                                          style: AppTextStyles.latin(size: 15, color: AppColors.textMuted, weight: FontWeight.bold),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Đăng nhập để xem mẫu ngữ pháp này',
                                                          style: AppTextStyles.latin(size: 13, color: AppColors.textFaint),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(Icons.lock_outline, color: AppColors.textFaint, size: 20),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Theme(
                                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                            child: ExpansionTile(
                                              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                                              expandedAlignment: Alignment.topLeft,
                                              title: Text(
                                                grammarPoint.title,
                                                style: AppTextStyles.latin(size: 15, color: AppColors.kanji, weight: FontWeight.bold),
                                              ),
                                              subtitle: Text(
                                                grammarPoint.subTitle,
                                                style: AppTextStyles.latin(size: 13, color: AppColors.textSecondary),
                                              ),
                                              children: [
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFDF7F2),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: const Color(0xFFFCD88A).withOpacity(0.3)),
                                                  ),
                                                  child: Text(
                                                    'Cấu trúc: ${grammarPoint.pattern}',
                                                    style: AppTextStyles.jp(size: 13, color: AppColors.brandDark, weight: FontWeight.w600),
                                                  ),
                                                ),
                                                if (grammarPoint.note.isNotEmpty) ...[
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    '💡 Giải thích: ${grammarPoint.note}',
                                                    style: AppTextStyles.latin(size: 13, color: AppColors.textSecondary),
                                                  ),
                                                ],
                                                if (grammarPoint.examples.isNotEmpty) ...[
                                                  const SizedBox(height: 12),
                                                  const Divider(height: 1, color: AppColors.border, thickness: 1),
                                                  const SizedBox(height: 12),
                                                  ...grammarPoint.examples.map((example) {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(bottom: 10),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            example.exampleJa,
                                                            style: AppTextStyles.jp(
                                                              size: 14,
                                                              color: AppColors.textPrimary,
                                                              weight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            example.exampleVi,
                                                            style: AppTextStyles.latin(size: 12, color: AppColors.textMuted),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }),
                                                ],
                                              ],
                                            ),
                                          ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

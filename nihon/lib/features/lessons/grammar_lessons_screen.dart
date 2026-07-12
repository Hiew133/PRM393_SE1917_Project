import 'package:flutter/material.dart';
import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/auth_screen.dart';
import 'kanji_data.dart';

class GrammarLessonsScreen extends StatelessWidget {
  const GrammarLessonsScreen({super.key});

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
          'Lộ trình Ngữ pháp',
          style: AppTextStyles.latin(size: 20, weight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: ValueListenableBuilder<List<GrammarPoint>>(
        valueListenable: DataRepository().grammarPointsNotifier,
        builder: (context, grammarPoints, child) {
          if (grammarPoints.isEmpty) {
            return Center(
              child: Text(
                'Chưa có bài học ngữ pháp nào.',
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
          );
        },
      ),
    );
  }
}

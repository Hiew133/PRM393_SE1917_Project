import 'package:flutter/material.dart';
import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/guest_lock_dialog.dart';
import '../games/football_quiz/football_quiz_screen.dart';
import 'kanji_data.dart';

class GrammarLessonsScreen extends StatelessWidget {
  const GrammarLessonsScreen({super.key});

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
      body: Column(
        children: [
          _PracticeBanner(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FootballQuizScreen()),
            ),
          ),
          Expanded(child: _buildGrammarList()),
        ],
      ),
    );
  }

  Widget _buildGrammarList() {
    return ValueListenableBuilder<List<GrammarPoint>>(
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
                  // Khách chỉ được thử 1 mẫu ngữ pháp đầu tiên.
                  final isLocked = isGuest && index >= 1;

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
                            onTap: () => showGuestLockDialog(context),
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
      );
  }
}

/// Nút "Luyện tập" mở trò chơi ngữ pháp kiểu đá bóng.
class _PracticeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PracticeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E8B57), Color(0xFF3BAD6C)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.speaking.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('⚽', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Luyện tập: Thủ môn bắt bóng',
                      style: AppTextStyles.latin(size: 15, weight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Trả lời ngữ pháp đúng để sút tung lưới!',
                      style: AppTextStyles.latin(size: 12.5, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}

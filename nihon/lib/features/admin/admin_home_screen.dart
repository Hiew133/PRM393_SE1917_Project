import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_config.dart';
import '../review/review_screen.dart';
import '../welcome/welcome_screen.dart';
import 'speaking/data/admin_repository.dart';
import 'speaking/speaking_admin_screen.dart';

/// Trang chủ Admin cấp APP — bày cả 5 kỹ năng như Dashboard học viên, nhưng
/// hiện CHỈ 話す (Nói) là mở; 4 kỹ năng còn lại để placeholder "sắp có".
/// Vào từ nút "Giảng viên" ở màn Welcome. Chạm 話す → [SpeakingAdminScreen].
/// (TODO: sau này chặn bằng phân quyền role khi đăng nhập thay cho mã PIN cũ.)
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Phần "$label" chưa được hỗ trợ — hiện chỉ làm phần Nói.'),
      duration: const Duration(seconds: 2),
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
            final totalSpeaking = repo.exams.length + repo.nihon1Exams.length;
            return Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      Text('Nội dung đang mở',
                          style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 12),
                      // 話す — soạn đề thi Nói.
                      _ActiveSkillCard(
                        jp: '話す',
                        vi: 'Luyện nói',
                        stat: '$totalSpeaking đề',
                        desc: 'Soạn đề thi Nói (JPD316 · JPD113)',
                        color: AppColors.speaking,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SpeakingAdminScreen()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 語彙 — mở màn Ôn tập ở chế độ Admin (CRUD giáo trình,
                      // bài học, từ vựng trên Firestore). Thoát ra thì tắt
                      // admin để học viên không thấy nút chỉnh sửa.
                      _ActiveSkillCard(
                        jp: '語彙',
                        vi: 'Từ vựng',
                        stat: 'CRUD',
                        desc: 'Quản lý giáo trình, bài học, từ vựng (Ôn tập)',
                        color: AppColors.vocab,
                        onTap: () {
                          AppConfig.isAdmin.value = true;
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                                  builder: (_) => const ReviewScreen()))
                              .then((_) => AppConfig.isAdmin.value = false);
                        },
                      ),
                      const SizedBox(height: 22),
                      Text('Sắp có', style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.55,
                        children: [
                          for (final s in _comingSkills)
                            _ComingSkillCard(
                              jp: s.$1,
                              vi: s.$2,
                              color: s.$3,
                              onTap: () => _comingSoon(context, s.$2),
                            ),
                        ],
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

  // Kỹ năng chưa mở (jp, vi, màu). Nghe hiện chưa có phần quản trị —
  // bài nghe đang đóng gói sẵn trong assets, không soạn qua Firestore.
  static const List<(String, String, Color)> _comingSkills = [
    ('漢字', 'Kanji', AppColors.kanji),
    ('読む', 'Đọc hiểu', AppColors.reading),
    ('聴く', 'Nghe', AppColors.listening),
  ];

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            // Về thẳng trang đầu (đăng nhập / Welcome).
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            ),
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
                    Text('Trang Giảng viên',
                        style: AppTextStyles.latin(
                            size: 19, weight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('ADMIN',
                          style: AppTextStyles.latin(
                              size: 9,
                              weight: FontWeight.w800,
                              color: const Color(0xFFF7C547),
                              letterSpacing: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Quản lý nội dung học tập',
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

/// Thẻ kỹ năng ĐANG MỞ — nổi bật, full-width.
class _ActiveSkillCard extends StatelessWidget {
  final String jp;
  final String vi;
  final String stat;
  final String desc;
  final Color color;
  final VoidCallback onTap;
  const _ActiveSkillCard({
    required this.jp,
    required this.vi,
    required this.stat,
    required this.desc,
    required this.color,
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
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(jp,
                    style: AppTextStyles.jp(
                        size: 22, weight: FontWeight.w700, color: color)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(vi,
                            style: AppTextStyles.latin(
                                size: 16,
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
                    const SizedBox(height: 3),
                    Text(desc,
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

/// Thẻ kỹ năng CHƯA MỞ — mờ, có nhãn "Sắp có".
class _ComingSkillCard extends StatelessWidget {
  final String jp;
  final String vi;
  final Color color;
  final VoidCallback onTap;
  const _ComingSkillCard({
    required this.jp,
    required this.vi,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(jp,
                        style: AppTextStyles.jp(
                            size: 17,
                            weight: FontWeight.w700,
                            color: color.withValues(alpha: 0.6))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('Sắp có',
                        style: AppTextStyles.latin(
                            size: 9,
                            weight: FontWeight.w700,
                            color: AppColors.textMuted)),
                  ),
                ],
              ),
              const Spacer(),
              Text(vi,
                  style: AppTextStyles.latin(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_config.dart';
import '../crud/crud_management_screen.dart';
import '../review/review_screen.dart';
import '../welcome/welcome_screen.dart';
import 'admin_ai_settings_screen.dart';
import 'speaking/data/admin_repository.dart';
import 'speaking/speaking_admin_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Phần "$label" chưa được hỗ trợ.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openManager(BuildContext context, int section) {
    RoleService().setRole(AppRole.admin);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminContentManagerScreen(section: section),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final speakingRepo = AdminRepository.instance;
    final dataRepository = DataRepository();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: speakingRepo,
          builder: (context, _) {
            final totalSpeaking =
                speakingRepo.exams.length + speakingRepo.nihon1Exams.length;
            final vocabularyCount = dataRepository.lessons.fold<int>(
              0,
              (total, lesson) => total + lesson.kanjis.length,
            );

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
                      _ActiveSkillCard(
                        jp: '話す',
                        vi: 'Luyện nói',
                        stat: '$totalSpeaking đề',
                        desc: 'Soạn đề thi Nói (JPD316 · JPD113)',
                        color: AppColors.speaking,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SpeakingAdminScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ActiveSkillCard(
                        jp: '漢字',
                        vi: 'Kanji',
                        stat: '$vocabularyCount chữ',
                        desc: 'Quản lý giáo trình, bài học, Kanji',
                        color: AppColors.kanji,
                        onTap: () => _openManager(context, 1),
                      ),
                      const SizedBox(height: 10),
                      _ActiveSkillCard(
                        jp: '語彙',
                        vi: 'Từ vựng',
                        stat: 'Firebase',
                        desc: 'Quản lý giáo trình, bài học và từ vựng',
                        color: AppColors.vocab,
                        onTap: () {
                          AppConfig.isAdmin.value = true;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ReviewScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _ActiveSkillCard(
                        jp: '文法',
                        vi: 'Ngữ pháp',
                        stat: '${dataRepository.grammarPoints.length} mẫu',
                        desc: 'Quản lý mẫu câu, ghi chú và ví dụ',
                        color: AppColors.reading,
                        onTap: () => _openManager(context, 2),
                      ),
                      const SizedBox(height: 10),
                      _ActiveSkillCard(
                        jp: '人',
                        vi: 'Tài khoản',
                        stat: 'User',
                        desc: 'Quản lý người dùng và phân quyền',
                        color: AppColors.brandDark,
                        onTap: () => _openManager(context, 0),
                      ),
                      /*
                            'Trợ lý học từ vựng, ngữ pháp và lộ trình ôn tập',
                      */
                      // const SizedBox(height: 10),
                      // _ActiveSkillCard(
                      //   jp: 'Key',
                      //   vi: 'API Key',
                      //   stat: 'Gemini',
                      //   desc:
                      //       'Cấu hình API key cho Nihon AI và chấm phát âm',
                      //   color: AppColors.listening,
                      //   onTap: () => Navigator.of(context).push(
                      //     MaterialPageRoute(
                      //       builder: (_) => const AdminAISettingsScreen(),
                      //     ),
                      //   ),
                      // ),
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
                          for (final skill in _comingSkills)
                            _ComingSkillCard(
                              jp: skill.$1,
                              vi: skill.$2,
                              color: skill.$3,
                              onTap: () => _comingSoon(context, skill.$2),
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

  static const List<(String, String, Color)> _comingSkills = [
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
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Trang Giảng viên',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.latin(
                          size: 22,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'ADMIN',
                        style: AppTextStyles.latin(
                          size: 9,
                          weight: FontWeight.w800,
                          color: const Color(0xFFF7C547),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Quản lý nội dung học tập',
                  style: AppTextStyles.latin(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  jp,
                  style: AppTextStyles.jp(
                    size: 24,
                    weight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.latin(
                              size: 18,
                              weight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            stat,
                            style: AppTextStyles.latin(
                              size: 10,
                              weight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.latin(
                        size: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

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
          padding: const EdgeInsets.all(16),
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
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      jp,
                      style: AppTextStyles.jp(
                        size: 18,
                        weight: FontWeight.w800,
                        color: color.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'Sắp có',
                      style: AppTextStyles.latin(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                vi,
                style: AppTextStyles.latin(
                  size: 14,
                  weight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

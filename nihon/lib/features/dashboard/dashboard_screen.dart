import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/skill.dart';
import '../speaking/level_select_screen.dart';
import '../welcome/welcome_screen.dart';
import 'widgets/daily_goal_card.dart';
import 'widgets/resume_card.dart';
import 'widgets/skill_card.dart';

/// Màn 02 – Dashboard / Trang chủ.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void openSpeaking() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const _UserHeader(),
        const SizedBox(height: 18),
        const DailyGoalCard(current: 30, target: 50),
        const SizedBox(height: 12),
        const ResumeCard(),
        const SizedBox(height: 20),
        Text('Các kỹ năng', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 12),
        // Lưới 2 cột cho 4 kỹ năng đầu + 1 hàng full-width cho kỹ năng cuối.
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            for (final skill in kSampleSkills.take(4)) SkillCard(skill: skill),
          ],
        ),
        const SizedBox(height: 10),
        // Luyện nói với AI — chỗ vào phần Nói (giữ DUY NHẤT một lối vào ở đây).
        _SpeakingButton(onTap: openSpeaking),
      ],
    );
  }
}

/// Nút nổi bật dẫn tới phần Luyện nói với AI.
class _SpeakingButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SpeakingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.speaking,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Luyện nói với AI',
                      style: AppTextStyles.latin(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '話す · Hội thoại tiếng Nhật cùng 田中先生',
                      style: AppTextStyles.jp(
                        size: 12,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.brand, AppColors.vocab],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'M',
            style: AppTextStyles.latin(
              size: 18,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'おはよう 🌸',
              style: AppTextStyles.latin(size: 12, color: AppColors.textMuted),
            ),
            Text(
              'K',
              style: AppTextStyles.latin(size: 17, weight: FontWeight.w700),
            ),
          ],
        ),
        const Spacer(),
        // Streak
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFCD88A)),
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                '15',
                style: AppTextStyles.latin(
                  size: 18,
                  weight: FontWeight.w800,
                  color: AppColors.listening,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Nút về trang đầu (đăng nhập / Welcome).
        GestureDetector(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.logout,
                size: 20, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

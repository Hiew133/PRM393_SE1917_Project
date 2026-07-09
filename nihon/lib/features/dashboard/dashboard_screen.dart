import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/skill.dart';
import 'widgets/daily_goal_cart.dart';
import 'widgets/resume_cart.dart';
import 'widgets/skill_cart.dart';

/// Màn 02 – Dashboard / Trang chủ.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onStartVocabReview});

  final VoidCallback? onStartVocabReview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const _UserHeader(),
        const SizedBox(height: 18),
        const DailyGoalCard(current: 30, target: 50),
        const SizedBox(height: 12),
        ResumeCard(onContinue: onStartVocabReview),
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
            for (final skill in kSampleSkills.take(4))
              SkillCard(
                skill: skill,
                onTap: skill.jpLabel == '語彙' ? onStartVocabReview : null,
              ),
          ],
        ),
        const SizedBox(height: 10),
        SkillCard(skill: kSampleSkills.last, wide: true),
      ],
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
      ],
    );
  }
}
import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/skill.dart';

/// Thẻ kỹ năng màu (語彙 / 漢字 / 読む ...).
///
/// [wide] = true để hiển thị dạng full-width (kỹ năng 話す trong thiết kế).
class SkillCard extends StatelessWidget {
  final Skill skill;
  final bool wide;

  const SkillCard({super.key, required this.skill, this.wide = false});

  @override
  Widget build(BuildContext context) {
    final progressBar = ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: skill.progress,
        minHeight: 3,
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        valueColor: AlwaysStoppedAnimation(
          Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );

    return Material(
      color: skill.color,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Stack(
          children: [
            // Hình tròn trang trí
            Positioned(
              right: -16,
              bottom: -16,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: wide ? _wideContent(progressBar) : _gridContent(progressBar),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridContent(Widget progressBar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skill.jpLabel,
              style: AppTextStyles.jp(
                size: 24,
                weight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              skill.viLabel,
              style: AppTextStyles.latin(
                size: 11,
                weight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skill.progressText,
              style: AppTextStyles.latin(
                size: 14,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            progressBar,
          ],
        ),
      ],
    );
  }

  Widget _wideContent(Widget progressBar) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              skill.jpLabel,
              style: AppTextStyles.jp(
                size: 22,
                weight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              skill.viLabel,
              style: AppTextStyles.latin(
                size: 11,
                weight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              skill.progressText,
              style: AppTextStyles.latin(
                size: 14,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(width: 130, child: progressBar),
          ],
        ),
      ],
    );
  }
}

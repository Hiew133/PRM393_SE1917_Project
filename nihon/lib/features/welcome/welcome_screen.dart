import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../home/main_navigation.dart';

/// Màn 01 – Welcome / Onboarding.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.welcomeBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            child: Column(
              children: [
                const Spacer(),
                // Logo minh hoạ
                Container(
                  width: 210,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '桜',
                    style: AppTextStyles.jp(
                      size: 80,
                      weight: FontWeight.w900,
                      color: AppColors.brand,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Logo + tên
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LogoBadge(),
                    const SizedBox(width: 10),
                    Text(
                      'さくら',
                      style: AppTextStyles.jp(
                        size: 34,
                        weight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Học tiếng Nhật mỗi ngày\ntheo phương pháp SRS khoa học',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.latin(
                    size: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                // Feature chips
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _FeatureChip('✓ 15,000+ từ vựng'),
                    _FeatureChip('✓ 2,136 Kanji'),
                    _FeatureChip('✓ JLPT N5 → N1'),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _start(context),
                  child: const Text('Bắt đầu miễn phí'),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.latin(
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'Đã có tài khoản? '),
                      TextSpan(
                        text: 'Đăng nhập',
                        style: AppTextStyles.latin(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '桜',
        style: AppTextStyles.jp(
          size: 24,
          weight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: AppTextStyles.latin(size: 12, weight: FontWeight.w600),
      ),
    );
  }
}
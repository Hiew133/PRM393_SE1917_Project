import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../lessons/kanji_data.dart';
import '../welcome/welcome_screen.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    RoleService().useGuestRole();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Thống kê',
          style: AppTextStyles.latin(size: 20, weight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('users').limit(100).snapshots(),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.hasError) {
                return Text(
                  'Không tải được thống kê tài khoản: ${usersSnapshot.error}',
                  style: AppTextStyles.latin(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                );
              }
              final users = usersSnapshot.data?.docs ?? [];
              final adminCount = users.where((doc) => doc.data()['role'] == 'admin').length;
              final customerCount = users.where((doc) => doc.data()['role'] == 'customer').length;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatTile(label: 'Tài khoản', value: users.length.toString(), icon: Icons.people_alt_outlined, color: AppColors.brand),
                  _StatTile(label: 'Admin', value: adminCount.toString(), icon: Icons.admin_panel_settings_outlined, color: AppColors.kanji),
                  _StatTile(label: 'Customer', value: customerCount.toString(), icon: Icons.person_outline, color: AppColors.reading),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<LessonData>>(
            valueListenable: DataRepository().lessonsNotifier,
            builder: (context, lessons, child) {
              final vocabularyCount = lessons.fold<int>(0, (sum, lesson) => sum + lesson.kanjis.length);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatTile(label: 'Bài học', value: lessons.length.toString(), icon: Icons.menu_book_outlined, color: AppColors.brandDark),
                  _StatTile(label: 'Từ vựng', value: vocabularyCount.toString(), icon: Icons.style_outlined, color: AppColors.vocab),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<GrammarPoint>>(
            valueListenable: DataRepository().grammarPointsNotifier,
            builder: (context, grammarPoints, child) {
              return _StatTile(
                label: 'Ngữ pháp',
                value: grammarPoints.length.toString(),
                icon: Icons.rule_outlined,
                color: AppColors.reading,
                fullWidth: true,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.latin(size: 20, color: AppColors.textPrimary, weight: FontWeight.bold),
                  ),
                  Text(
                    label,
                    style: AppTextStyles.latin(size: 12, color: AppColors.textMuted, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

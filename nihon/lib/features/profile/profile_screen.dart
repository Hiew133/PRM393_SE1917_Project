import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../admin/admin_home_screen.dart';
import '../auth/auth_screen.dart';
import '../welcome/welcome_screen.dart';

const List<String> kAvatarEmojis = [
  '🌸', '🦊', '🐱', '🐼', '🦁', '🍣', '🍙', '🍡', '🍵', '🏯', '🎓', '⛩️', '🏮', '👾', '🚀', '🐕'
];

const List<List<Color>> kAvatarGradients = [
  [Color(0xFFFF9A9E), Color(0xFFFECFEF)], // Soft Pink
  [Color(0xFFA1C4FD), Color(0xFFC2E9FB)], // Sky Blue
  [Color(0xFF84FAB0), Color(0xFF8FD3F4)], // Mint Green
  [Color(0xFFFAD0C4), Color(0xFFFFD1FF)], // Peach Pink
  [Color(0xFFF6D365), Color(0xFFFDA085)], // Sunset Orange
  [Color(0xFFA6C0FE), Color(0xFFF1EEFD)], // Lavender Purple
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedGoal = 'N5';
  bool _notificationsEnabled = true;

  void _showGoalSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn mục tiêu JLPT của bạn',
                  style: AppTextStyles.latin(size: 18, weight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...['N5', 'N4', 'N3', 'N2', 'N1'].map((level) {
                  final isSelected = _selectedGoal == level;
                  return ListTile(
                    title: Text(
                      'JLPT $level',
                      style: AppTextStyles.latin(
                        size: 16,
                        weight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.brand : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.brand) : null,
                    onTap: () {
                      setState(() => _selectedGoal = level);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAvatarSelector(
    BuildContext context,
    String currentEmoji,
    int currentColorIndex,
    String userId,
  ) {
    String selectedEmoji = currentEmoji;
    int selectedColorIndex = currentColorIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: AppColors.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final gradient = kAvatarGradients[selectedColorIndex.clamp(0, kAvatarGradients.length - 1)];

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Thay đổi Avatar',
                    style: AppTextStyles.latin(size: 18, weight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Avatar Preview
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        selectedEmoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Emoji Selection
                  Text(
                    'Chọn biểu tượng',
                    style: AppTextStyles.latin(size: 14, weight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 55,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: kAvatarEmojis.length,
                      itemBuilder: (context, idx) {
                        final emoji = kAvatarEmojis[idx];
                        final isSelected = selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedEmoji = emoji);
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.brand.withOpacity(0.1) : AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.brand : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Gradient Selection
                  Text(
                    'Chọn màu nền',
                    style: AppTextStyles.latin(size: 14, weight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: kAvatarGradients.length,
                      itemBuilder: (context, idx) {
                        final colors = kAvatarGradients[idx];
                        final isSelected = selectedColorIndex == idx;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedColorIndex = idx);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.brand : Colors.transparent,
                                width: isSelected ? 3 : 0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colors[0].withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: () async {
                      final firestore = FirebaseFirestore.instanceFor(
                        app: Firebase.app(),
                        databaseId: 'default',
                      );
                      await firestore.collection('users').doc(userId).set({
                        'avatarEmoji': selectedEmoji,
                        'avatarColorIndex': selectedColorIndex,
                      }, SetOptions(merge: true));
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Lưu thay đổi',
                      style: AppTextStyles.latin(size: 15, weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    RoleService().useGuestRole();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = RoleService().currentRole.value == AppRole.guest || user == null;

    if (isGuest) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Trang cá nhân',
            style: AppTextStyles.latin(size: 20, weight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9A9E).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Trang cá nhân bị khóa',
                  style: AppTextStyles.latin(
                    size: 22,
                    weight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vui lòng đăng nhập hoặc đăng ký tài khoản để thiết lập mục tiêu học tập, quản lý thông báo nhắc nhở và đồng bộ chuỗi ngày học của bạn nhé!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.latin(
                    size: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen(startRegister: false)),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Đăng nhập / Đăng ký'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    textStyle: AppTextStyles.latin(
                      size: 15,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final email = user.email ?? 'Khách';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'G';

    final firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Trang cá nhân',
          style: AppTextStyles.latin(size: 20, weight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          // 1. Profile Header Card
          isGuest
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.brand, AppColors.brand.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: AppTextStyles.latin(size: 24, weight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              style: AppTextStyles.latin(size: 16, weight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.textMuted.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Khách',
                                style: AppTextStyles.latin(size: 11, weight: FontWeight.w700, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: firestore.collection('users').doc(user.uid).snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data();
                    final String avatarEmoji = data?['avatarEmoji'] as String? ?? '';
                    final int avatarColorIndex = data?['avatarColorIndex'] as int? ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.01),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showAvatarSelector(
                                  context,
                                  avatarEmoji.isNotEmpty ? avatarEmoji : '🌸',
                                  avatarColorIndex,
                                  user.uid,
                                ),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: avatarEmoji.isNotEmpty
                                          ? kAvatarGradients[avatarColorIndex.clamp(0, kAvatarGradients.length - 1)]
                                          : [AppColors.brand, AppColors.brand.withOpacity(0.7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (avatarEmoji.isNotEmpty
                                                ? kAvatarGradients[avatarColorIndex.clamp(0, kAvatarGradients.length - 1)][0]
                                                : AppColors.brand)
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    avatarEmoji.isNotEmpty ? avatarEmoji : initial,
                                    style: TextStyle(
                                      fontSize: avatarEmoji.isNotEmpty ? 34 : 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black12, blurRadius: 4),
                                    ],
                                  ),
                                  child: const Icon(Icons.edit, size: 10, color: AppColors.brand),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.latin(
                                    size: 16,
                                    weight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ValueListenableBuilder<AppRole>(
                                  valueListenable: RoleService().currentRole,
                                  builder: (context, role, child) {
                                    final roleText = switch (role) {
                                      AppRole.admin => 'Giảng viên (Admin)',
                                      AppRole.customer => 'Học viên',
                                      AppRole.guest => 'Khách',
                                    };
                                    final roleColor = switch (role) {
                                      AppRole.admin => AppColors.kanji,
                                      AppRole.customer => AppColors.brandDark,
                                      AppRole.guest => AppColors.textMuted,
                                    };

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: roleColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        roleText,
                                        style: AppTextStyles.latin(
                                          size: 11,
                                          weight: FontWeight.w700,
                                          color: roleColor,
                                        ),
                                      ),
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
                ),
          const SizedBox(height: 20),

          // 2. Guest prompt card if applicable
          if (isGuest) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFCD88A).withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đăng nhập tài khoản 🚀',
                    style: AppTextStyles.latin(size: 15, weight: FontWeight.bold, color: AppColors.brandDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đăng nhập để đồng bộ kết quả học tập, làm đầy đủ bài kiểm tra và mở khóa toàn bộ kho tài liệu Kanji & Ngữ pháp!',
                    style: AppTextStyles.latin(size: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen(startRegister: false)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đăng nhập hoặc Đăng ký'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 3. Learning Stats (Only visible if not Guest)
          if (!isGuest) ...[
            Text('Tiến độ học tập', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 10),
            ValueListenableBuilder<Map<String, int>>(
              valueListenable: DataRepository().xpHistoryNotifier,
              builder: (context, _, child) {
                final streakCount = DataRepository().streak;
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Chuỗi ngày',
                        value: '$streakCount ngày',
                        icon: '🔥',
                        color: AppColors.listening,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Mục tiêu',
                        value: 'JLPT $_selectedGoal',
                        icon: '🎯',
                        color: AppColors.vocab,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // 4. Menu Settings List
          Text('Cài đặt & Tài khoản', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.track_changes_rounded,
                  iconColor: AppColors.vocab,
                  title: 'Mục tiêu JLPT',
                  subtitle: 'Mục tiêu hiện tại: JLPT $_selectedGoal',
                  onTap: _showGoalSelector,
                ),
                const Divider(height: 1, color: AppColors.border),
                _MenuTile(
                  icon: Icons.notifications_none_rounded,
                  iconColor: AppColors.listening,
                  title: 'Thông báo nhắc nhở',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeColor: AppColors.brand,
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                    },
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                ValueListenableBuilder<bool>(
                  valueListenable: RoleService().showAiAssistant,
                  builder: (context, show, child) {
                    return _MenuTile(
                      icon: Icons.psychology_outlined,
                      iconColor: AppColors.brandDark,
                      title: 'Hiển thị Trợ lý AI',
                      subtitle: 'Hiện nút chat AI trôi nổi ngoài màn hình',
                      trailing: Switch(
                        value: show,
                        activeColor: AppColors.brand,
                        onChanged: (val) {
                          RoleService().showAiAssistant.value = val;
                        },
                      ),
                    );
                  },
                ),
                // Admin Control Panel
                ValueListenableBuilder<AppRole>(
                  valueListenable: RoleService().currentRole,
                  builder: (context, role, child) {
                    if (role != AppRole.admin) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const Divider(height: 1, color: AppColors.border),
                        _MenuTile(
                          icon: Icons.admin_panel_settings_outlined,
                          iconColor: AppColors.kanji,
                          title: 'Trang quản trị (Admin)',
                          subtitle: 'Quản lý bài học, Kanji và tài khoản',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                if (!isGuest) ...[
                  const Divider(height: 1, color: AppColors.border),
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.red,
                    title: 'Đăng xuất',
                    titleColor: Colors.red,
                    onTap: _logout,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            color.withOpacity(0.04),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.latin(size: 12, color: AppColors.textSecondary, weight: FontWeight.w600),
              ),
              Text(icon, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.latin(
              size: 18,
              weight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: AppTextStyles.latin(
          size: 15,
          weight: FontWeight.bold,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.latin(size: 12, color: AppColors.textMuted),
            )
          : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textFaint) : null),
      onTap: onTap,
    );
  }
}
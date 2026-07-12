import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../chat/ai_chat_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../lessons/lessons_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import '../review/review_screen.dart';

/// Khung chính chứa BottomNavigationBar – 5 tab như trong thiết kế.
const List<List<Color>> kAvatarGradients = [
  [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
  [Color(0xFFA1C4FD), Color(0xFFC2E9FB)],
  [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
  [Color(0xFFFAD0C4), Color(0xFFFFD1FF)],
  [Color(0xFFF6D365), Color(0xFFFDA085)],
  [Color(0xFFA6C0FE), Color(0xFFF1EEFD)],
];

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  final DataRepository _repository = DataRepository();
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;

  }

  @override
  void dispose() {

    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void goToTab(int index) {
    if (index < 0 || index >= _tabCount) return;
    setState(() => _index = index);
  }

  static const _tabCount = 5;

  int get _dueReviewCount {
    final now = DateTime.now();
    return _repository.srsCards
        .where((card) => !card.nextReview.isAfter(now))
        .length;
  }

  Widget _reviewIcon({required bool selected}) {
    return Icon(
      Icons.autorenew,
      color: selected ? AppColors.brand : AppColors.textFaint,
    );
  }

  late final List<Widget> _tabs = List.generate(_tabCount, (i) {
    switch (i) {
      case 0:
        return DashboardScreen(onStartVocabReview: () => goToTab(2));
      case 1:
        return const LessonsScreen();
      case 2:
        return const ReviewScreen();
      case 3:
        return const ProgressScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: _tabs[_index]),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: RoleService().showAiAssistant,
        builder: (context, show, child) {
          if (!show) return const SizedBox.shrink();
          final user = FirebaseAuth.instance.currentUser;
          final isGuest = RoleService().currentRole.value == AppRole.guest || user == null;
          final email = user?.email ?? '';
          final initial = email.isNotEmpty ? email[0].toUpperCase() : 'G';
          final firestore = FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'default',
          );
      
          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AIChatScreen()),
                  );
                },
                child: isGuest
                    ? Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE94057).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '🤖',
                          style: TextStyle(fontSize: 28),
                        ),
                      )
                    : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: firestore.collection('users').doc(user.uid).snapshots(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data();
                          final String avatarEmoji = data?['avatarEmoji'] as String? ?? '';
                          final int avatarColorIndex = data?['avatarColorIndex'] as int? ?? 0;
      
                          return Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: avatarEmoji.isNotEmpty
                                    ? kAvatarGradients[avatarColorIndex.clamp(0, kAvatarGradients.length - 1)]
                                    : [AppColors.brand, AppColors.vocab],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (avatarEmoji.isNotEmpty
                                          ? kAvatarGradients[avatarColorIndex.clamp(0, kAvatarGradients.length - 1)][0]
                                          : AppColors.brand)
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              avatarEmoji.isNotEmpty ? avatarEmoji : initial,
                              style: TextStyle(
                                fontSize: avatarEmoji.isNotEmpty ? 28 : 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.surfaceAlt,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.brand : AppColors.textFaint,
              );
            }),
          ),
          child: NavigationBar(
            height: 64,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppColors.textFaint),
                selectedIcon: Icon(Icons.home, color: AppColors.brand),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined, color: AppColors.textFaint),
                selectedIcon: Icon(Icons.menu_book, color: AppColors.brand),
                label: 'Bài học',
              ),
              NavigationDestination(
                icon: _reviewIcon(selected: false),
                selectedIcon: _reviewIcon(selected: true),
                label: 'Ôn tập',
              ),

              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined, color: AppColors.textFaint),
                selectedIcon: Icon(Icons.bar_chart, color: AppColors.brand),
                label: 'Tiến độ',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: AppColors.textFaint),
                selectedIcon: Icon(Icons.person, color: AppColors.brand),
                label: 'Cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

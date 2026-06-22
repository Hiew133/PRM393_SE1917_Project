import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../lessons/lessons_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import '../review/review_screen.dart';

/// Khung chính chứa BottomNavigationBar – 5 tab như trong thiết kế.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  static const _tabs = <Widget>[
    DashboardScreen(),
    LessonsScreen(),
    ReviewScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: _tabs[_index]),
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
            destinations: const [
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
                icon: Badge(
                  label: Text('8'),
                  backgroundColor: AppColors.vocab,
                  child: Icon(Icons.autorenew, color: AppColors.textFaint),
                ),
                selectedIcon: Icon(Icons.autorenew, color: AppColors.brand),
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

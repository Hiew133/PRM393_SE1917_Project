import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../admin/admin_home_screen.dart';
import '../home/main_navigation.dart';
import '../welcome/welcome_screen.dart';
import 'locked_account_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingAuth();
        }
        // Tài khoản ẩn danh (do module Luyện nghe tạo để lưu yêu thích theo
        // máy) KHÔNG phải đăng nhập thật — vẫn coi là Guest, không được vào
        // như customer.
        if (user == null || user.isAnonymous) {
          RoleService().useGuestRole();
          return const WelcomeScreen();
        }

        return FutureBuilder<AppRole>(
          future: RoleService().loadRoleForUser(user),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState != ConnectionState.done) {
              return const _LoadingAuth();
            }
            final role = roleSnapshot.data ?? RoleService().currentRole.value;

            if (RoleService().isLocked.value) {
              return const LockedAccountScreen();
            }

            if (role.canManageContent) {
              return const AdminHomeScreen();
            }
            return const MainNavigation();
          },
        );
      },
    );
  }
}

class _LoadingAuth extends StatelessWidget {
  const _LoadingAuth();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Đang tải tài khoản...',
          style: AppTextStyles.latin(size: 14, color: AppColors.textMuted, weight: FontWeight.w600),
        ),
      ),
    );
  }
}

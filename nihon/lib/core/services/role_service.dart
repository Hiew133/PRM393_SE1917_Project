import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../utils/app_config.dart';

enum AppRole {
  admin,
  customer,
  guest,
}

extension AppRoleInfo on AppRole {
  String get label {
    switch (this) {
      case AppRole.admin:
        return 'Admin';
      case AppRole.customer:
        return 'Customer';
      case AppRole.guest:
        return 'Guest';
    }
  }

  bool get canManageContent => this == AppRole.admin;
}

class RoleService {
  RoleService._internal() {
    // AppConfig.isAdmin (cờ bật UI quản trị) LUÔN đi theo role thật từ
    // Firestore — không còn cách nào khác để bật nó ngoài đăng nhập admin.
    currentRole.addListener(() {
      AppConfig.isAdmin.value = currentRole.value == AppRole.admin;
    });
  }

  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;

  final ValueNotifier<AppRole> currentRole = ValueNotifier(AppRole.guest);
  final ValueNotifier<bool> isLocked = ValueNotifier(false);
  final ValueNotifier<bool> showAiAssistant = ValueNotifier(false);

  static const Set<String> _adminEmails = {
    'admin@gmail.com',
    'duybohshl@gmail.com',
  };
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  void setRole(AppRole role) {
    currentRole.value = role;
    if (role == AppRole.guest) {
      isLocked.value = false;
    }
  }

  Future<AppRole> loadRoleForUser(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    try {
      final snap = await ref.get().timeout(const Duration(seconds: 8));
      String? rawRole = snap.data()?['role'] as String?;
      bool locked = snap.data()?['isLocked'] as bool? ?? false;
      isLocked.value = locked;

      // Tự động gán quyền Admin cho email của bạn
      if (_isAdminEmail(user.email)) {
        rawRole = 'admin';
      }

      final role = _roleFromString(rawRole);

      if (!snap.exists) {
        await ref.set({
          'email': user.email,
          'role': role.name,
          'isLocked': false,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 8));
      } else if (_isAdminEmail(user.email) && snap.data()?['role'] != 'admin') {
        await ref.update({'role': 'admin'}).timeout(const Duration(seconds: 8));
      }

      currentRole.value = role;
      return role;
    } catch (_) {
      if (_isAdminEmail(user.email)) {
        currentRole.value = AppRole.admin;
        isLocked.value = false;
        return AppRole.admin;
      } else {
        currentRole.value = AppRole.customer;
        isLocked.value = false;
        return AppRole.customer;
      }
    }
  }

  Future<AppRole> createCustomerProfile(User user) async {
    final role = _isAdminEmail(user.email) ? AppRole.admin : AppRole.customer;
    currentRole.value = role;
    isLocked.value = false;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'role': role.name,
        'isLocked': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Keep the user moving with the default customer role if Firestore is slow.
    }
    return role;
  }

  void useGuestRole() {
    currentRole.value = AppRole.guest;
    isLocked.value = false;
  }

  bool _isAdminEmail(String? email) {
    return _adminEmails.contains(email?.trim().toLowerCase());
  }

  AppRole _roleFromString(String? value) {
    switch (value) {
      case 'admin':
        return AppRole.admin;
      case 'customer':
        return AppRole.customer;
      default:
        return AppRole.customer;
    }
  }
}

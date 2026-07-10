import 'package:flutter/material.dart';

class AppConfig {
  /// Biến notifier toàn cục để quản lý quyền Admin.
  /// Bất kỳ UI nào lắng nghe biến này đều sẽ tự động vẽ lại khi có thay đổi.
  static final ValueNotifier<bool> isAdmin = ValueNotifier<bool>(false);
}

import 'package:shared_preferences/shared_preferences.dart';

/// Đếm số lần đăng nhập SAI mật khẩu và tạm khoá đăng nhập khi vượt ngưỡng.
///
/// Lưu cục bộ theo email (SharedPreferences): trước khi đăng nhập thành công,
/// app CHƯA có quyền đọc/ghi document Firestore của user đó (rules yêu cầu
/// đã xác thực), nên không thể đếm phía server. Đây là hàng rào phía client
/// chống dò mật khẩu ngay trên thiết bị — đủ cho phạm vi ứng dụng.
class LoginAttemptService {
  LoginAttemptService._();

  /// Sai từ ngưỡng này bắt đầu cảnh báo đỏ.
  static const int warnThreshold = 2;

  /// Sai đủ ngưỡng này thì khoá đăng nhập.
  static const int lockThreshold = 5;

  /// Thời gian khoá sau khi vượt ngưỡng.
  static const Duration lockDuration = Duration(minutes: 30);

  static const String _failPrefix = 'login_fail_count_';
  static const String _lockPrefix = 'login_locked_until_';

  static String _norm(String email) => email.trim().toLowerCase();
  static String _failKey(String email) => '$_failPrefix${_norm(email)}';
  static String _lockKey(String email) => '$_lockPrefix${_norm(email)}';

  /// Thời gian khoá còn lại cho [email], hoặc `null` nếu không bị khoá.
  /// Hết hạn khoá thì tự dọn dẹp và trả `null`.
  static Future<Duration?> lockRemaining(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final untilMs = prefs.getInt(_lockKey(email));
    if (untilMs == null) return null;
    final remaining = DateTime.fromMillisecondsSinceEpoch(untilMs)
        .difference(DateTime.now());
    if (remaining <= Duration.zero) {
      // Hết khoá: reset để lần tới đếm lại từ đầu.
      await prefs.remove(_lockKey(email));
      await prefs.remove(_failKey(email));
      return null;
    }
    return remaining;
  }

  /// Ghi nhận một lần đăng nhập sai. Trả về [LoginAttemptStatus] cho biết
  /// đã sai bao nhiêu lần và có vừa bị khoá không.
  static Future<LoginAttemptStatus> recordFailure(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_failKey(email)) ?? 0) + 1;
    await prefs.setInt(_failKey(email), count);

    if (count >= lockThreshold) {
      final until = DateTime.now().add(lockDuration);
      await prefs.setInt(_lockKey(email), until.millisecondsSinceEpoch);
      return LoginAttemptStatus(
        failCount: count,
        justLocked: true,
        lockRemaining: lockDuration,
      );
    }
    return LoginAttemptStatus(failCount: count);
  }

  /// Xoá bộ đếm khi đăng nhập thành công.
  static Future<void> reset(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failKey(email));
    await prefs.remove(_lockKey(email));
  }
}

/// Kết quả sau một lần đăng nhập sai.
class LoginAttemptStatus {
  final int failCount;
  final bool justLocked;
  final Duration? lockRemaining;

  const LoginAttemptStatus({
    required this.failCount,
    this.justLocked = false,
    this.lockRemaining,
  });

  /// Đã tới ngưỡng bắt đầu cảnh báo đỏ chưa (nhưng chưa khoá).
  bool get shouldWarn =>
      !justLocked && failCount >= LoginAttemptService.warnThreshold;

  /// Số lần sai còn lại trước khi bị khoá.
  int get remainingBeforeLock =>
      (LoginAttemptService.lockThreshold - failCount).clamp(0, LoginAttemptService.lockThreshold);
}

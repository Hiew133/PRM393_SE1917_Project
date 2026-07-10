import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'app.dart';
// Tool seed dữ liệu Firestore — bỏ comment import này cùng 2 dòng gọi trong
// main() khi cần upload dữ liệu bài học.
// import 'core/utils/firebase_uploader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Firebase (cần cho Firebase AI Logic).
  // Bọc try/catch để nếu Firebase lỗi thì app vẫn vào được (không trắng màn);
  // khi đó tính năng AI sẽ báo lỗi gọn trong màn Luyện nói.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // App Check: Firebase AI Logic luôn cưỡng chế ("Basic - Enforced") nên
    // request KHÔNG có token sẽ bị chặn. Lúc DEV dùng debug provider: chạy app
    // 1 lần rồi lấy debug token in ra (logcat/console trình duyệt) và đăng ký
    // trong Firebase Console → App Check → Manage debug tokens.
    // Khi lên production: đổi androidProvider → playIntegrity, webProvider →
    // reCAPTCHA site key thật.
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kReleaseMode
            ? const AndroidPlayIntegrityProvider()
            : const AndroidDebugProvider(),
        // Web bắt buộc truyền provider; ở chế độ debug (bật cờ trong
        // web/index.html) SDK bỏ qua reCAPTCHA và dùng debug token.
        providerWeb: ReCaptchaV3Provider(_webRecaptchaSiteKey),
      );
    } catch (e, st) {
      debugPrint('App Check activate failed: $e\n$st');
    }
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
  }

  // Tool seed dữ liệu Firestore (core/utils/firebase_uploader.dart) —
  // bỏ comment khi cần upload dữ liệu bài học rồi comment lại.
  //await uploadNhat2Lesson7Data();
  //await checkDatabaseCounts();

  runApp(const SakuraApp());
}

/// reCAPTCHA v3 site key cho App Check trên Web.
/// - DEV: chỉ cần là chuỗi placeholder vì đã bật debug token trong index.html.
/// - PRODUCTION: thay bằng site key thật (Firebase Console → App Check → web app
///   → reCAPTCHA v3) qua: --dart-define=RECAPTCHA_SITE_KEY=xxxx
const String _webRecaptchaSiteKey = String.fromEnvironment(
  'RECAPTCHA_SITE_KEY',
  defaultValue: 'recaptcha-v3-placeholder',
);

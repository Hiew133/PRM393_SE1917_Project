import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/data_repository.dart';
import 'core/services/speech_assessment_service.dart';
import 'firebase_options.dart';
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
    // request KHÔNG có token sẽ bị chặn. Lúc DEV dùng debug provider với
    // TOKEN CHUNG của team (_androidDebugToken) — đăng ký 1 LẦN trong
    // Firebase Console → App Check → app `com.example.layout` → Manage debug
    // tokens là mọi máy dev chạy được, không cần add token từng máy.
    // Khi lên production: đổi androidProvider → playIntegrity, webProvider →
    // reCAPTCHA site key thật.
    // Bản APK "dùng thử" gửi tay (sideload) không qua Google Play nên
    // Play Integrity sẽ fail → build với
    //   flutter build apk --release --dart-define=USE_DEBUG_APPCHECK=true
    // để bản release đó vẫn dùng debug token chung. Bản phát hành chính
    // thức lên Play Store thì KHÔNG bật cờ này.
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: (kReleaseMode && !_useDebugAppCheck)
            ? const AndroidPlayIntegrityProvider()
            : const AndroidDebugProvider(debugToken: _androidDebugToken),
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

  await SpeechAssessmentService().loadSavedApiKey();
  DataRepository().init();

  runApp(const SakuraApp());
}

/// Bật để bản RELEASE dùng debug token App Check thay vì Play Integrity —
/// dành cho APK dùng thử gửi tay (không cài qua Google Play).
const bool _useDebugAppCheck = bool.fromEnvironment(
  'USE_DEBUG_APPCHECK',
  defaultValue: false,
);

/// Debug token App Check DÙNG CHUNG cho team (Android, chỉ bản debug).
/// Đã đăng ký trong Firebase Console → App Check → `com.example.layout`
/// → Manage debug tokens. Máy mới clone repo về là chạy được luôn.
/// Có thể override bằng: --dart-define=APP_CHECK_DEBUG_TOKEN=xxxx
/// (Token này chỉ có tác dụng bypass App Check lúc dev — không dùng ở release.)
const String _androidDebugToken = String.fromEnvironment(
  'APP_CHECK_DEBUG_TOKEN',
  defaultValue: '00b89c8c-2636-491a-971c-35c1b6d19cdf',
);

/// reCAPTCHA v3 site key cho App Check trên Web.
/// - DEV: chỉ cần là chuỗi placeholder vì đã bật debug token trong index.html.
/// - PRODUCTION: thay bằng site key thật (Firebase Console → App Check → web app
///   → reCAPTCHA v3) qua: --dart-define=RECAPTCHA_SITE_KEY=xxxx
const String _webRecaptchaSiteKey = String.fromEnvironment(
  'RECAPTCHA_SITE_KEY',
  defaultValue: 'recaptcha-v3-placeholder',
);

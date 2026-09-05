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
    // request KHÔNG có token sẽ bị chặn. Lúc DEV dùng debug provider; token
    // truyền qua --dart-define=APP_CHECK_DEBUG_TOKEN, KHÔNG hard-code vào
    // repo (xem _androidDebugToken bên dưới). Bỏ trống thì SDK tự sinh token
    // cho máy đó, in ra log, mình chép vào Firebase Console → App Check →
    // app `com.example.layout` → Manage debug tokens.
    // Khi lên production: Android tự dùng Play Integrity; web cần reCAPTCHA
    // site key thật qua --dart-define=RECAPTCHA_SITE_KEY.
    // Bản APK "dùng thử" gửi tay (sideload) không qua Google Play nên
    // Play Integrity sẽ fail → build với
    //   flutter build apk --release --dart-define=USE_DEBUG_APPCHECK=true \
    //     --dart-define=APP_CHECK_DEBUG_TOKEN=<token>
    // Bản phát hành chính thức lên Play Store thì KHÔNG bật cờ này.
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: (kReleaseMode && !_useDebugAppCheck)
            ? const AndroidPlayIntegrityProvider()
            : AndroidDebugProvider(
                debugToken:
                    _androidDebugToken.isEmpty ? null : _androidDebugToken,
              ),
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

/// Debug token App Check cho Android (chỉ dùng lúc dev).
///
/// KHÔNG ghi token thẳng vào đây. Debug token bypass hoàn toàn App Check —
/// ai đọc được là gọi Firebase nhân danh app này được. Truyền lúc build:
///   `flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=token-của-máy-bạn`
///
/// Bỏ trống thì SDK tự sinh token riêng cho máy đó và in ra log lúc chạy; chép
/// token đó vào Firebase Console → App Check → Manage debug tokens là máy chạy
/// được. Mỗi máy một token riêng, thu hồi từng cái được khi cần.
const String _androidDebugToken = String.fromEnvironment(
  'APP_CHECK_DEBUG_TOKEN',
);

/// reCAPTCHA v3 site key cho App Check trên Web.
/// - DEV: chỉ cần là chuỗi placeholder vì đã bật debug token trong index.html.
/// - PRODUCTION: thay bằng site key thật (Firebase Console → App Check → web app
///   → reCAPTCHA v3) qua: --dart-define=RECAPTCHA_SITE_KEY=xxxx
const String _webRecaptchaSiteKey = String.fromEnvironment(
  'RECAPTCHA_SITE_KEY',
  defaultValue: 'recaptcha-v3-placeholder',
);

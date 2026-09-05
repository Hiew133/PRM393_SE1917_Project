/// Cấu hình gọi Gemini qua **Firebase AI Logic**.
///
/// ✅ Với Firebase AI Logic, **KHÔNG có API key nào nằm trong app**.
/// App gọi Gemini thông qua Firebase; việc xác thực do Firebase + App Check lo.
/// Đây là cách an toàn để dùng cho production (key không thể bị moi từ APK/IPA).
///
/// Xác thực được cấu hình bằng file native của Firebase:
///   - Android: android/app/google-services.json
///   - iOS:     ios/Runner/GoogleService-Info.plist
/// (sinh ra khi chạy `flutterfire configure` — xem hướng dẫn).
class ApiConfig {
  ApiConfig._();

  /// Model Gemini dùng cho Firebase AI Logic.
  /// Có thể override khi build: `--dart-define=GEMINI_MODEL=gemini-3.6-flash`
  static const String model = String.fromEnvironment(
    'GEMINI_MODEL',
    // Backend là GEMINI DEVELOPER API (googleAI), không phải Vertex AI: Vertex
    // đòi bật billing, project đang ở gói free nên trả 403.
    //
    // Dùng alias `-latest` thay vì ghim phiên bản: gemini-2.5-flash đã bị gỡ
    // ("no longer available to new users") và làm chết toàn bộ tính năng AI.
    // Alias chỉ tồn tại bên Developer API - đúng backend đang dùng.
    defaultValue: 'gemini-flash-latest',
  );
}

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
  /// Có thể override khi build: `--dart-define=GEMINI_MODEL=gemini-2.5-flash-lite`
  static const String model = String.fromEnvironment(
    'GEMINI_MODEL',
    // Provider hiện tại là VERTEX AI (xem ai_conversation_service): phải dùng
    // tên model tường minh — alias kiểu `gemini-flash-latest` chỉ tồn tại bên
    // Gemini Developer API. Trên Vertex trả phí không còn lo 503 "high demand".
    defaultValue: 'gemini-2.5-flash',
  );
}

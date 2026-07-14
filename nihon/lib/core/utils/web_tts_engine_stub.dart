import 'dart:typed_data';

/// Bản rỗng của [WebTtsEngine] cho các nền tảng KHÔNG phải web —
/// mobile/desktop dùng flutter_tts như cũ, không bao giờ gọi vào đây.
class WebTtsEngine {
  WebTtsEngine._();

  static final WebTtsEngine instance = WebTtsEngine._();

  bool get isSupported => false;

  Future<bool> ensureJapaneseVoice({
    Duration timeout = const Duration(milliseconds: 1500),
  }) async =>
      false;

  Future<void> speak(
    String text, {
    void Function()? onStart,
    void Function()? onEnd,
    double rate = 0.85,
  }) async {
    onEnd?.call();
  }

  Future<void> playWav(
    Uint8List wav, {
    void Function()? onStart,
    void Function()? onEnd,
  }) async {
    onEnd?.call();
  }

  void stop() {}
}

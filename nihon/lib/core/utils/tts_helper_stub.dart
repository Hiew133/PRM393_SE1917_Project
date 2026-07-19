import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts _tts = FlutterTts();
bool _configured = false;

/// Đọc to một câu tiếng Nhật trên Android/iOS bằng flutter_tts.
/// (Bản web dùng Web Speech API — xem tts_helper_web.dart.)
void speakJapanese(String text) {
  if (text.isEmpty) return;
  () async {
    if (!_configured) {
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(0.45);
      _configured = true;
    }
    await _tts.stop();
    await _tts.speak(text);
  }();
}

import '../services/gemini_tts_service.dart';
import 'web_tts_engine_web.dart';

/// Đọc to một câu tiếng Nhật trên web (nút loa ở màn ôn tập / kanji).
///
/// Đi qua [WebTtsEngine] thay vì eval() thẳng speechSynthesis như trước —
/// engine tự chọn voice ja-JP khi trình duyệt nạp xong voice và tự gỡ các
/// trạng thái kẹt của Chrome (trước đây "lúc nghe được lúc không").
/// Máy không có voice tiếng Nhật → fallback Gemini TTS (Firebase AI Logic).
void speakJapanese(String text) {
  _speak(text);
}

Future<void> _speak(String text) async {
  final engine = WebTtsEngine.instance;
  if (await engine.ensureJapaneseVoice()) {
    await engine.speak(text);
    return;
  }
  final wav = await GeminiTtsService.instance.synthesizeWav(text);
  if (wav != null) {
    await engine.playWav(wav);
  }
}

import 'web_tts_engine_web.dart';

/// Đọc to một câu tiếng Nhật trên web (nút loa ở màn ôn tập / kanji).
///
/// Đi qua [WebTtsEngine] thay vì eval() thẳng speechSynthesis như trước —
/// engine tự chọn voice ja-JP khi trình duyệt nạp xong voice và tự gỡ các
/// trạng thái kẹt của Chrome (trước đây "lúc nghe được lúc không").
void speakJapanese(String text) {
  WebTtsEngine.instance.speak(text);
}

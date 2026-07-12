import 'dart:convert';
import 'dart:js' as js;

void speakJapanese(String text) {
  try {
    js.context.callMethod('eval', [
      """
      if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel(); // Dừng phát giọng nói trước đó nếu đang chạy
        var utter = new SpeechSynthesisUtterance(${jsonEncode(text)});
        utter.lang = 'ja-JP';
        utter.rate = 0.85; // Tốc độ nói vừa phải để dễ nghe
        window.speechSynthesis.speak(utter);
      }
      """
    ]);
  } catch (e) {
    // Bỏ qua lỗi trong môi trường test
  }
}

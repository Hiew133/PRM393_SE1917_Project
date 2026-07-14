/// TTS gọi thẳng Web Speech API — thay cho flutter_tts trên WEB.
///
/// flutter_tts bản web (4.2.5) có 2 lỗi làm "lúc nghe được tiếng lúc không":
///  1. Plugin chỉ speak khi state nội bộ là stopped/paused; sau cancel()
///     Chrome có thể KHÔNG bắn onend → state kẹt ở playing → mọi speak() sau
///     đó bị nuốt im lặng vĩnh viễn (còn kẹt ở paused thì nó resume() nhầm
///     utterance CŨ thay vì đọc câu mới).
///  2. setLanguage() chọn voice đúng MỘT lần lúc init, nhưng Chrome nạp danh
///     sách voice bất đồng bộ — lúc init getVoices() thường rỗng nên không
///     voice ja-JP nào được gắn; có tiếng hay không phụ thuộc voice load kịp
///     hay chưa.
///
/// Engine này: tạo utterance MỚI mỗi lần đọc, chọn lại voice tiếng Nhật khi
/// trình duyệt bắn voiceschanged, watchdog tự thử lại khi Chrome "nuốt"
/// utterance, và keep-alive pause/resume chống bug Chrome cắt tiếng sau ~15s
/// với voice mạng (Google 日本語).
library;

import 'dart:async';
import 'dart:js_interop';

@JS('speechSynthesis')
external _SpeechSynthesis? get _synthOrNull;

extension type _SpeechSynthesis._(JSObject _) implements JSObject {
  external void speak(_Utterance utterance);
  external void cancel();
  external void pause();
  external void resume();
  external JSArray<_Voice> getVoices();
  external bool get speaking;
  external bool get paused;
  external bool get pending;
  external set onvoiceschanged(JSFunction? handler);
}

extension type _Utterance._(JSObject _) implements JSObject {
  external factory _Utterance(String text);
  external set lang(String value);
  external set rate(num value);
  external set voice(_Voice value);
  external set onstart(JSFunction? handler);
  external set onend(JSFunction? handler);
  external set onerror(JSFunction? handler);
}

extension type _Voice._(JSObject _) implements JSObject {
  external String get name;
  external String get lang;
  external bool get localService;
}

class WebTtsEngine {
  WebTtsEngine._() {
    final synth = _synthOrNull;
    if (synth == null) return;
    _jaVoice = _pickJaVoice();
    // Chrome nạp voice bất đồng bộ — chọn lại khi danh sách sẵn sàng.
    synth.onvoiceschanged = (JSAny _) {
      _jaVoice ??= _pickJaVoice();
    }.toJS;
  }

  static final WebTtsEngine instance = WebTtsEngine._();

  bool get isSupported => _synthOrNull != null;

  _Voice? _jaVoice;

  /// Giữ tham chiếu utterance đang đọc — Chrome có bug GC utterance giữa
  /// chừng làm mất luôn sự kiện onend.
  // ignore: unused_field
  _Utterance? _current;

  /// Tăng mỗi lần speak/stop để callback của utterance cũ không đè phiên mới.
  int _generation = 0;

  Timer? _watchdog;
  Timer? _keepAlive;
  Timer? _failsafe;

  /// Đọc [text] bằng giọng tiếng Nhật. [onStart]/[onEnd] bắn theo audio thật
  /// (dùng cho lip-sync). Gọi lại khi đang đọc sẽ ngắt câu cũ.
  Future<void> speak(
    String text, {
    void Function()? onStart,
    void Function()? onEnd,
    double rate = 0.85,
  }) async {
    final synth = _synthOrNull;
    if (synth == null || text.isEmpty) {
      onEnd?.call();
      return;
    }

    final generation = ++_generation;
    _clearTimers();
    synth.cancel();
    synth.resume(); // gỡ trạng thái paused "kẹt" còn sót của Chrome

    _jaVoice ??= _pickJaVoice();
    final voice = _jaVoice;

    var started = false;
    var finished = false;
    void finish() {
      if (finished || generation != _generation) return;
      finished = true;
      _clearTimers();
      _current = null;
      onEnd?.call();
    }

    final utterance = _Utterance(text)
      ..lang = 'ja-JP'
      ..rate = rate;
    if (voice != null) utterance.voice = voice;
    utterance.onstart = (JSAny _) {
      if (generation != _generation) return;
      started = true;
      onStart?.call();
      _startKeepAlive(voice);
    }.toJS;
    utterance.onend = ((JSAny _) => finish()).toJS;
    utterance.onerror = ((JSAny _) => finish()).toJS;
    _current = utterance;

    // Chrome nuốt utterance nếu speak() quá sát sau cancel() → nhả một nhịp.
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (generation != _generation) return;
    synth.speak(utterance);
    synth.resume(); // Chrome đôi khi xếp hàng đợi ở trạng thái paused

    // Watchdog: 500ms chưa kêu mà engine cũng rảnh → thử lại đúng 1 lần.
    _watchdog = Timer(const Duration(milliseconds: 500), () {
      if (generation != _generation || started) return;
      if (synth.paused) {
        synth.resume();
      } else if (!synth.speaking && !synth.pending) {
        synth.cancel();
        synth.resume();
        synth.speak(utterance);
      }
    });

    // Failsafe: onend thất lạc (tab nền, voice mạng rớt) thì vẫn trả trạng
    // thái "đọc xong" để UI không kẹt miệng nhân vật — thời lượng ước dư dả.
    _failsafe = Timer(
      Duration(milliseconds: 4000 + text.length * 400),
      finish,
    );
  }

  /// Ngắt mọi âm thanh đang đọc/đang chờ.
  void stop() {
    _generation++;
    _clearTimers();
    _current = null;
    final synth = _synthOrNull;
    if (synth == null) return;
    synth.cancel();
    synth.resume();
  }

  /// Voice mạng (Google 日本語…) bị Chrome cắt sau ~15s — pause/resume định kỳ
  /// giữ cho nó chạy tiếp. Voice cài trong máy không dính bug này.
  void _startKeepAlive(_Voice? voice) {
    if (voice != null && voice.localService) return;
    _keepAlive?.cancel();
    _keepAlive = Timer.periodic(const Duration(seconds: 10), (_) {
      final synth = _synthOrNull;
      if (synth == null || !synth.speaking) return;
      synth.pause();
      synth.resume();
    });
  }

  _Voice? _pickJaVoice() {
    final synth = _synthOrNull;
    if (synth == null) return null;
    _Voice? remote;
    for (final voice in synth.getVoices().toDart) {
      if (!voice.lang.toLowerCase().startsWith('ja')) continue;
      // Ưu tiên voice cài trong máy: không cần mạng, không dính bug cắt 15s.
      if (voice.localService) return voice;
      remote ??= voice;
    }
    return remote;
  }

  void _clearTimers() {
    _watchdog?.cancel();
    _keepAlive?.cancel();
    _failsafe?.cancel();
  }
}

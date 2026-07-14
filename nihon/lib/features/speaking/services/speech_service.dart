import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/services/gemini_tts_service.dart';
import '../../../core/utils/web_tts_engine.dart';

/// Bọc thu âm giọng nói (STT) và đọc câu tiếng Nhật (TTS).
///
/// Cần quyền micro:
///  - Android: RECORD_AUDIO trong AndroidManifest.xml
///  - iOS: NSMicrophoneUsageDescription + NSSpeechRecognitionUsageDescription
///    trong Info.plist
class SpeechService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttReady = false;
  bool _ttsSpeaking = false;
  bool _jaVoiceOk = true; // thiết bị có giọng đọc tiếng Nhật không

  /// Tăng mỗi lần speak/stop trên web — hủy kết quả Gemini TTS về muộn
  /// (người dùng đã bấm mic ngắt lời trong lúc chờ server tổng hợp audio).
  int _webSpeakSeq = 0;

  /// Báo trạng thái TTS (true = đang đọc). Nhân vật ảo dùng để lip-sync:
  /// miệng chỉ cử động trong lúc audio đang phát.
  void Function(bool speaking)? onSpeakingChanged;

  /// Báo một phiên STT vừa kết thúc (hết câu / im lặng lâu). Controller dùng
  /// để TỰ MỞ LẠI phiên nghe khi người dùng chưa bấm dừng (người mới học hay
  /// ngắc ngứ, không thể để STT tự chốt câu giữa chừng).
  void Function()? onSessionDone;

  /// Báo lỗi STT (tên lỗi gốc của plugin/trình duyệt, vd "network",
  /// "not-allowed", "audio-capture"). Controller lọc và dịch ra thông báo —
  /// KHÔNG nuốt lỗi ở đây nữa vì từng làm "nghe mà không ra chữ" không dò được.
  void Function(String errorMsg, bool permanent)? onSttError;

  /// Khởi tạo STT (xin quyền + kiểm tra thiết bị có hỗ trợ không).
  Future<bool> init() async {
    _sttReady = await _stt.initialize(
      onError: (e) => onSttError?.call(e.errorMsg, e.permanent),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          onSessionDone?.call();
        }
      },
    );
    // WEB: KHÔNG dùng flutter_tts — bản web của plugin hay kẹt state sau
    // cancel() và không gắn được voice ja-JP khi voice nạp muộn (lỗi "lúc
    // nghe được lúc không"). Đi thẳng Web Speech API qua WebTtsEngine.
    if (!kIsWeb) {
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(0.45); // chậm để dễ nghe
      // Máy ảo Android thường THIẾU dữ liệu giọng tiếng Nhật → TTS im lặng mà
      // không báo gì. Kiểm tra để controller còn hiện cảnh báo cho người dùng.
      try {
        final avail = await _tts.isLanguageAvailable('ja-JP');
        _jaVoiceOk = avail == true;
      } catch (_) {
        _jaVoiceOk = true; // không kiểm tra được thì đừng báo oan
      }
      _tts.setStartHandler(() {
        _ttsSpeaking = true;
        onSpeakingChanged?.call(true);
      });
      void ttsDone() {
        _ttsSpeaking = false;
        onSpeakingChanged?.call(false);
      }

      _tts.setCompletionHandler(ttsDone);
      _tts.setCancelHandler(ttsDone);
      _tts.setErrorHandler((_) => ttsDone());
    }
    return _sttReady;
  }

  bool get isAvailable => _sttReady;
  bool get isListening => _stt.isListening;

  /// Thiết bị có giọng đọc tiếng Nhật không (Android emulator hay thiếu).
  bool get jaVoiceAvailable => _jaVoiceOk;

  /// Bắt đầu nghe. [onResult] trả về văn bản tiếng Nhật nhận diện được khi
  /// người dùng nói xong (kết quả cuối).
  ///
  /// Dùng **dictation mode** + nới `pauseFor`/`listenFor` để KHÔNG bị cắt câu
  /// dài khi người nói ngừng một nhịp giữa câu (mode mặc định "confirmation"
  /// chốt ngay sau 1-2 từ đầu).
  Future<void> startListening({
    required void Function(String text) onResult,
    void Function(String text)? onPartial,
  }) async {
    if (!_sttReady) return;

    Future<void> doListen() => _stt.listen(
          onResult: (result) {
            if (!result.finalResult) {
              // Kết quả tạm thời (live) trong lúc đang nói.
              onPartial?.call(result.recognizedWords);
            } else if (result.recognizedWords.isNotEmpty) {
              onResult(result.recognizedWords);
            }
          },
          listenOptions: SpeechListenOptions(
            // Android native nhận "ja_JP"; web thì plugin gán thẳng chuỗi này
            // vào SpeechRecognition.lang — phải là BCP-47 "ja-JP", nếu sai
            // trình duyệt rơi về ngôn ngữ hệ thống (nhận ra "Konichiwa"
            // dạng romaji thay vì tiếng Nhật).
            localeId: kIsWeb ? 'ja-JP' : 'ja_JP',
            partialResults: true, // giữ nhận diện liên tục cho câu dài
            listenMode: ListenMode.dictation,
            // KHÔNG hủy khi gặp lỗi: lúc ngừng giữa câu thiết bị hay bắn
            // speech_timeout — nếu hủy (cancelOnError=true) thì phần đã nói
            // trong phiên bị VỨT MẤT (đây là lỗi "nói ngắt quãng mất chữ").
            cancelOnError: false,
            // Tối đa 2 phút mỗi lượt; chịu được ngừng ~15s giữa câu để gom trọn
            // câu dài, nói ngập ngừng cũng không bị cắt phiên sớm.
            listenFor: const Duration(seconds: 120),
            pauseFor: const Duration(seconds: 15),
          ),
        );

    try {
      await doListen();
    } catch (e) {
      // Web: plugin báo phiên cũ đã dừng nhưng SpeechRecognition của trình
      // duyệt CÒN CHẠY → listen() mới ném InvalidStateError "recognition has
      // already started" và mic "điếc" từ đó (UI vẫn tưởng đang nghe). Hủy hẳn
      // phiên ma rồi thử lại một lần.
      try {
        await _stt.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await doListen();
      } catch (e2) {
        onSttError?.call('listen-failed: $e2', true);
      }
    }
  }

  Future<void> stopListening() => _stt.stop();

  /// Ngắt TTS đang đọc dở (ví dụ khi người dùng bấm mic để nói).
  ///
  /// CHỈ cancel khi thật sự đang đọc — Chrome web dễ "kẹt" engine nếu cancel
  /// lúc rảnh rồi speak ngay sau đó (mất tiếng).
  Future<void> stopSpeaking() async {
    if (kIsWeb) {
      // Engine web tự xử lý mọi trạng thái kẹt — cancel luôn an toàn.
      _webSpeakSeq++;
      WebTtsEngine.instance.stop();
      if (_ttsSpeaking) {
        _ttsSpeaking = false;
        onSpeakingChanged?.call(false);
      }
      return;
    }
    if (!_ttsSpeaking) return;
    await _tts.stop();
    _ttsSpeaking = false;
    // Một số platform không bắn cancel handler khi stop() → tự báo.
    onSpeakingChanged?.call(false);
  }

  /// Đọc to một câu tiếng Nhật (nút "▶ Nghe" / AI tự đọc câu trả lời).
  ///
  /// LUÔN stop() trước khi đọc (kể cả khi cờ báo đang rảnh): engine Chrome có
  /// thể "kẹt ma" ở trạng thái đang nói dù cờ [_ttsSpeaking] đã tắt (utterance
  /// bị hủy giữa chừng) — không stop thì câu mới xếp hàng sau và im lặng mãi.
  /// Sau stop chờ 150ms vì Chrome nuốt utterance mới nếu speak() sát sau cancel.
  Future<void> speak(String japanese) async {
    if (japanese.isEmpty) return;
    if (kIsWeb) {
      final seq = ++_webSpeakSeq;
      void started() {
        _ttsSpeaking = true;
        onSpeakingChanged?.call(true);
      }

      void ended() {
        _ttsSpeaking = false;
        onSpeakingChanged?.call(false);
      }

      final engine = WebTtsEngine.instance;
      if (await engine.ensureJapaneseVoice()) {
        if (seq != _webSpeakSeq) return;
        await engine.speak(japanese, onStart: started, onEnd: ended);
        return;
      }
      // Trình duyệt không có voice ja-JP (đọc bằng voice mặc định sẽ im
      // lặng) → tổng hợp audio bằng Gemini TTS rồi phát WAV.
      final wav = await GeminiTtsService.instance.synthesizeWav(japanese);
      if (seq != _webSpeakSeq) return; // người dùng đã ngắt trong lúc chờ
      if (wav != null) {
        await engine.playWav(wav, onStart: started, onEnd: ended);
      }
      return;
    }
    await _tts.stop();
    _ttsSpeaking = false;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await _tts.speak(japanese);
  }

  void dispose() {
    _stt.cancel();
    if (kIsWeb) {
      WebTtsEngine.instance.stop();
    } else {
      _tts.stop();
    }
  }
}

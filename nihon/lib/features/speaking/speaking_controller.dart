import 'package:flutter/foundation.dart';

import 'models/chat_message.dart';
import 'models/scenario.dart';
import 'services/ai_conversation_service.dart';
import 'services/reading_match.dart';
import 'services/speaking_history_service.dart';
import 'services/speech_service.dart';

/// Trạng thái + logic cho màn luyện nói (chế độ AI 会話).
class SpeakingController extends ChangeNotifier {
  final AiConversationService _ai;
  final SpeechService _speech;

  SpeakingController({
    AiConversationService? ai,
    SpeechService? speech,
    Scenario? initialScenario,
  })  : _ai = ai ?? AiConversationService(),
        _speech = speech ?? SpeechService(),
        _scenario = initialScenario ?? kScenarios.first {
    // Trạng thái TTS → nhân vật ảo lip-sync (miệng cử động khi đang đọc).
    _speech.onSpeakingChanged = (speaking) {
      if (_disposed) return;
      _aiSpeaking = speaking;
      notifyListeners();
    };
    // Phiên STT tự chốt (do ngừng nói lâu) → mở lại ngay nếu người dùng chưa
    // bấm dừng, để người mới học nói ngắc ngứ không bị cắt câu giữa chừng.
    _speech.onSessionDone = _onSttSessionDone;
    _speech.onSttError = _onSttError;
  }

  /// Lỗi STT: bỏ qua lỗi "im lặng" bình thường (no-speech/no-match — cơ chế
  /// gom-nhiều-phiên tự xử lý), còn lỗi CÓ Ý NGHĨA (quyền, thiết bị thu,
  /// network của Web Speech, ngôn ngữ) thì dịch ra banner để dò được nguyên
  /// nhân "nghe mà không ra chữ".
  void _onSttError(String msg, bool permanent) {
    debugPrint('STT error: $msg (permanent: $permanent)');
    if (_disposed || !_listening) return;
    final m = msg.toLowerCase();
    // "Không nghe thấy gì" là chuyện BÌNH THƯỜNG (im lặng, người học ngập ngừng,
    // emulator không có mic) — KHÔNG phải lỗi. Bỏ qua để cơ chế tự mở lại phiên
    // nghe tiếp; đừng dọa người dùng bằng banner đỏ. speech_timeout/no-match
    // tuy plugin gắn cờ permanent nhưng vẫn thuộc nhóm này.
    if (m.contains('speech_timeout') ||
        m.contains('speech-timeout') ||
        m.contains('no-speech') ||
        m.contains('no_speech') ||
        m.contains('no-match') ||
        m.contains('no_match')) {
      return;
    }
    String? friendly;
    if (m.contains('not-allowed') ||
        m.contains('not_allowed') ||
        m.contains('permission') ||
        m.contains('insufficient')) {
      friendly = 'Trình duyệt/hệ điều hành đang CHẶN quyền micro với trang này '
          '(lỗi: $msg). Kiểm tra lại quyền mic của Chrome và Windows.';
    } else if (m.contains('audio')) {
      friendly = 'Không thu được âm thanh từ micro (lỗi: $msg). Kiểm tra '
          'Windows → Sound → Input có nhận tiếng không, và mic có bị app khác '
          'chiếm không.';
    } else if (m.contains('network')) {
      friendly = 'Dịch vụ nhận diện giọng nói của trình duyệt không kết nối '
          'được máy chủ (lỗi: network). Thử: tắt VPN/proxy nếu có, hoặc chạy '
          'bằng Edge: flutter run -d edge --web-port=5544.';
    } else if (m.contains('language') || m.contains('locale')) {
      friendly = 'Trình duyệt báo không hỗ trợ nhận diện tiếng Nhật '
          '(lỗi: $msg). Thử chạy bằng Edge hoặc cập nhật Chrome.';
    } else if (permanent) {
      // Lỗi lạ nhưng chết hẳn (vd mở lại phiên thất bại cả sau khi cancel) —
      // đừng để mic "điếc câm lặng": báo ra và tắt nghe cho người dùng thử lại.
      friendly = 'Micro gặp lỗi ($msg). Bấm dừng rồi mở mic thử lại.';
    }
    if (friendly != null) {
      _error = friendly;
      notifyListeners();
    }
  }

  // ── Trạng thái ────────────────────────────────────────
  final List<ChatMessage> messages = [];
  Scenario _scenario;
  bool _busy = false; // đang gọi AI
  bool _listening = false; // mic đang MỞ (có thể trải qua nhiều phiên STT)
  bool _finishing = false; // vừa bấm dừng, đang đợi STT nhả kết quả cuối (~400ms)
  bool _aiSpeaking = false; // TTS đang đọc (nhân vật đang "nói")
  bool _disposed = false;
  String _transcript = ''; // các đoạn đã chốt (gom qua nhiều phiên STT)
  String _partial = ''; // chữ đang nhận diện trực tiếp (live)
  // Đoạn partial được "chốt tạm" vào _transcript lúc đổi phiên (phiên STT chết
  // không kịp bắn kết quả chốt — hay gặp khi im lặng giữa câu). Nhớ lại để nếu
  // bản chốt thật về trễ thì thay thế, không nối lặp.
  String _flushedTail = '';
  String? _draft; // câu đã chốt sau khi bấm dừng — chờ xem lại/sửa rồi mới gửi
  String _draftPendingTail = ''; // đuôi draft đến từ partial CHƯA chốt (chờ bản chốt về trễ thay thế)
  String? _error;

  // Chế độ THI Nhật 1 (JPD113). Phase/tiến độ TÍNH CỤC BỘ theo số lượt SV đã
  // trả lời (0=đọc bài, 1–3=theo tranh, 4=tự do, 5=xong) — không tin phần model
  // tự khai để tránh model nhảy cóc/kết thúc sớm làm UI đi theo.
  int _answeredCount = 0; // số lượt SV đã trả lời thành công
  String? _examProgress; // "Đọc bài", "Câu 2/4", "Hoàn thành"
  String? _examPhase; // "reading" | "picture" | "free" | "done"
  bool _examFinished = false; // đã xong toàn bộ phần thi

  // Chế độ Tự do / JPD316: người dùng chủ động kết thúc buổi luyện → AI phân
  // tích cả buổi hội thoại rồi khóa mic; "Luyện lại" mở phiên mới.
  bool _sessionEnded = false;
  bool _analyzing = false; // đang chờ AI phân tích cuối buổi
  SessionAnalysis? _analysis; // kết quả phân tích (null = chưa kết thúc)
  String? _historyDocId; // doc lịch sử đã lưu (để gắn thêm phân tích, khỏi trùng)

  Scenario get scenario => _scenario;
  bool get busy => _busy;
  bool get listening => _listening;
  bool get finishing => _finishing;
  bool get aiSpeaking => _aiSpeaking;

  /// Toàn bộ chữ đã nói tới giờ (đoạn đã chốt + đoạn đang nhận diện live).
  String get partialText =>
      _partial.isEmpty ? _transcript : '$_transcript$_partial';

  /// Câu chờ gửi (sau khi bấm dừng): người dùng xem lại rồi chọn xóa nói lại /
  /// nói thêm / gửi. null = không ở chế độ xem lại.
  String? get draft => _draft;
  String? get error => _error;
  bool get speechAvailable => _speech.isAvailable;

  bool get isExamDrill => _scenario.examDrill;

  /// Loại kỳ thi format cứng (Nhật 1 / Nhật 2 / none) — UI dùng để hiển thị
  /// đúng cơ cấu điểm và nhãn.
  ExamDrillType get drillType => _scenario.drillType;

  /// Bài đọc lấy THẲNG từ dữ liệu đề trong máy (không nhờ AI chép lại).
  String? get readingPassage => _scenario.readingPassage;
  String? get readingPassageVi => _scenario.readingPassageVi;
  String? get examProgress => _examProgress;
  String? get examPhase => _examPhase;
  bool get examFinished => _examFinished;
  bool get sessionEnded => _sessionEnded;
  bool get analyzing => _analyzing;
  SessionAnalysis? get analysis => _analysis;

  /// Thuần giọng nói cho MỌI chế độ (Tự do / JPD316 / thi Nhật 1 / Nhật 2):
  /// không hiện text khi đang luyện — dừng mic là GỬI luôn, như thi nói thật.
  /// Bản nháp (draft) chỉ còn xuất hiện khi lượt gửi bị lỗi mạng, để bấm gửi
  /// lại mà không phải nói lại từ đầu.
  bool get voiceOnly => true;

  /// Điểm từng lượt nói của SV theo thứ tự (thi Nhật 1: [0]=đọc bài,
  /// [1..3]=câu theo tranh, [4]=câu tự do) — null nếu lượt đó AI không chấm.
  List<int?> get examTurnScores => messages
      .where((m) => m.fromUser)
      .map((m) => m.pronunciationScore)
      .toList();

  /// Đã có ít nhất một lượt nói của người dùng (điều kiện hiện nút Kết thúc).
  bool get hasUserTurn => messages.any((m) => m.fromUser);

  Future<void> init() async {
    await _speech.init();
    await selectScenario(_scenario);
    // Đặt SAU selectScenario (nó reset _error). Thiết bị (thường là máy ảo
    // Android) thiếu giọng đọc tiếng Nhật → TTS sẽ im lặng: báo sớm cho người
    // dùng biết thay vì "mất tiếng" khó hiểu.
    if (!_speech.jaVoiceAvailable && _error == null) {
      _error = 'Thiết bị chưa có giọng đọc tiếng Nhật nên AI không đọc to được. '
          'Trên máy ảo/điện thoại: Cài đặt → Google TTS → cài dữ liệu giọng '
          '日本語, hoặc test bằng Chrome.';
      notifyListeners();
    }
  }

  /// Đổi tình huống → reset hội thoại và lấy lời chào mở đầu của AI.
  Future<void> selectScenario(Scenario s) async {
    _scenario = s;
    messages.clear();
    _error = null;
    _draft = null;
    _answeredCount = 0;
    _sessionEnded = false;
    _analyzing = false;
    _analysis = null;
    _historyDocId = null;
    _syncExamState();
    messages.add(ChatMessage.pendingAi());
    _busy = true;
    notifyListeners();

    try {
      final turn = await _ai.startScenario(s);
      _replacePendingWithAi(turn);
    } catch (e) {
      _failPending(e.toString());
    }
    _busy = false;
    notifyListeners();
  }

  /// Bấm mic lần 1: MỞ mic (thu gom lời nói, kể cả khi nói ngắc ngứ — STT tự
  /// chốt phiên vì im lặng thì mở lại phiên mới, KHÔNG gửi).
  /// Bấm mic lần 2 (nút dừng): chốt toàn bộ những gì đã nói và GỬI cho AI.
  Future<void> toggleMic() async {
    // _finishing: đang chốt phiên nghe cũ — bấm mic lúc này sẽ mở phiên mới
    // đè lên phiên đang đóng và làm mất chữ, nên bỏ qua.
    if (_busy || _finishing || _examFinished || _sessionEnded) return;
    if (_listening) {
      await _finishListening();
      return;
    }
    if (!_speech.isAvailable) {
      _error = 'Thiết bị không hỗ trợ nhận diện giọng nói hoặc chưa cấp quyền micro.';
      notifyListeners();
      return;
    }
    // Ngắt AI đang đọc dở để không thu tiếng TTS lẫn vào mic.
    await _speech.stopSpeaking();
    _listening = true;
    // Đang có bản nháp mà bấm mic → NÓI THÊM: giữ lại phần đã có.
    _transcript = (_draft == null || _draft!.trim().isEmpty)
        ? ''
        : '${_draft!.trim()} ';
    _draft = null;
    _partial = '';
    _flushedTail = '';
    _error = null;
    _sttQuickFails = 0; // lượt mở mic mới → làm lại từ đầu chuỗi đếm lỗi
    notifyListeners();
    _startSttSession();
  }

  /// Mở một phiên nghe STT; kết quả chốt của phiên được GOM vào [_transcript]
  /// (chưa gửi — chỉ gửi khi người dùng bấm dừng).
  void _startSttSession() {
    _sttSessionStart = DateTime.now();
    _speech.startListening(
      onResult: (text) {
        if (_disposed) return;
        _sttQuickFails = 0; // mic có nhận chữ → chuỗi phiên lỗi bị cắt
        // Kết quả cuối về TRỄ (sau khi đã chốt draft ở _finishListening) →
        // gộp vào draft để không rơi mất chữ cuối câu. Nếu draft đang kết
        // thúc bằng bản partial CHƯA CHỐT của cùng đoạn nói này thì thay nó
        // bằng bản chốt (tránh lặp chữ), không thì nối thêm.
        if (!_listening && _draft != null) {
          var base = _draft!;
          if (_draftPendingTail.isNotEmpty && base.endsWith(_draftPendingTail)) {
            base = base
                .substring(0, base.length - _draftPendingTail.length)
                .trimRight();
          }
          _draftPendingTail = '';
          _draft = base.isEmpty ? text : '$base $text'.trim();
          notifyListeners();
          return;
        }
        var t = text.trim();
        // Đoạn cuối transcript có thể là bản PARTIAL được "chốt tạm" lúc đổi
        // phiên (_flushPendingPartial). Nếu bản chốt thật của nó về trễ →
        // thay/bỏ để không bị lặp câu.
        if (_flushedTail.isNotEmpty && _transcript.endsWith('$_flushedTail ')) {
          final overlap =
              t.startsWith(_flushedTail) || _flushedTail.startsWith(t);
          if (overlap) {
            if (t.length > _flushedTail.length) {
              // Bản chốt đầy đủ hơn → gỡ bản tạm, dùng bản chốt.
              _transcript = _transcript.substring(
                  0, _transcript.length - _flushedTail.length - 1);
            } else {
              t = ''; // bản tạm đã đủ → bỏ bản chốt trễ
            }
          }
        }
        _flushedTail = '';
        if (t.isNotEmpty) {
          _transcript = _transcript.isEmpty ? '$t ' : '$_transcript$t ';
        }
        _partial = '';
        notifyListeners();
      },
      onPartial: (text) {
        if (_disposed || !_listening) return;
        final t = text.trim();
        // Bộ nhận diện (nhất là online) hay bắn bản RỖNG lúc ngừng/đổi cụm.
        // KHÔNG để bản rỗng đè xoá phần đã nghe — chỉ cập nhật khi có chữ. Vì
        // recognizer ở đây gần như KHÔNG trả "final", partial cuối chính là câu.
        if (t.isEmpty) return;
        _sttQuickFails = 0;
        _partial = t;
        notifyListeners();
      },
    );
  }

  // Chống vòng lặp mở lại phiên STT vô hạn khi mic hỏng giữa chừng (bị app
  // khác chiếm / quyền bị thu): phiên chết "nhanh" (< _kQuickFailWindow, không
  // nhận được chữ nào) liên tiếp quá _kMaxQuickFails lần → tự tắt mic + báo lỗi.
  // Phiên im lặng bình thường sống ≥ pauseFor (~5s) nên không bị tính nhầm.
  DateTime _sttSessionStart = DateTime.now();
  int _sttQuickFails = 0;
  static const _kQuickFailWindow = Duration(seconds: 2);
  static const _kMaxQuickFails = 3;

  /// Phiên STT vừa kết thúc (tự chốt do ngừng nói / hết thời gian). Nếu người
  /// dùng CHƯA bấm dừng → mở lại phiên mới để nghe tiếp.
  void _onSttSessionDone() {
    if (_disposed || !_listening) return;
    if (DateTime.now().difference(_sttSessionStart) < _kQuickFailWindow) {
      _sttQuickFails++;
      if (_sttQuickFails >= _kMaxQuickFails) {
        _giveUpListening();
        return;
      }
    } else {
      _sttQuickFails = 0;
    }
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!_disposed && _listening && !_speech.isListening) {
        _flushPendingPartial();
        _startSttSession();
      }
    });
  }

  /// Phiên STT vừa chết mà chưa bắn kết quả chốt (vd bị hủy vì im lặng giữa
  /// câu) → CHỐT TẠM phần partial còn treo vào [_transcript] trước khi mở
  /// phiên mới, để câu đã nói không bị partial của phiên mới đè mất.
  void _flushPendingPartial() {
    final t = _partial.trim();
    _partial = '';
    if (t.isEmpty) return;
    _flushedTail = t;
    _transcript = _transcript.isEmpty ? '$t ' : '$_transcript$t ';
    notifyListeners();
  }

  /// Mic hỏng liên tục → tắt nghe, giữ lại phần đã nói (nếu có) làm draft.
  void _giveUpListening() {
    _listening = false;
    final text = partialText.trim();
    _transcript = '';
    _partial = '';
    _draft = text.isEmpty ? _draft : text;
    _error = 'Không nghe được từ micro (thiết bị bận hoặc quyền bị thu hồi). '
        'Kiểm tra micro rồi bấm mic thử lại.';
    notifyListeners();
  }

  /// Bấm nút dừng: đóng mic, chờ STT nhả nốt kết quả cuối.
  /// - Chế độ hội thoại thuần giọng nói ([voiceOnly]): GỬI câu luôn cho AI.
  /// - Chế độ thi: đưa vào [draft] để XEM LẠI (sửa/nói thêm/xóa) rồi mới gửi.
  Future<void> _finishListening() async {
    _listening = false; // chặn _onSttSessionDone tự mở lại phiên
    _finishing = true; // khóa nút mic trong lúc chờ gom kết quả cuối
    notifyListeners();
    String text;
    try {
      await _speech.stopListening();
      // stop() xong plugin mới bắn kết quả cuối — đợi một nhịp để gom nốt.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      text = partialText.trim();
      // Nhớ phần đuôi mới chỉ có bản partial: nếu bản CHỐT của nó về trễ hơn
      // 400ms, onResult sẽ thay đuôi này thay vì nối lặp.
      _draftPendingTail = _partial.trim();
      _transcript = '';
      _partial = '';
      _draft = (voiceOnly || text.isEmpty) ? null : text;
    } finally {
      _finishing = false;
    }
    notifyListeners();
    if (voiceOnly && text.isNotEmpty) {
      await submitUserText(text);
    }
  }

  /// Gửi bản nháp cho AI (bấm nút gửi). Nháp rỗng → chỉ đóng chế độ xem lại.
  Future<void> sendDraft() async {
    if (_busy || _finishing) return;
    final text = (_draft ?? '').trim();
    _draft = null;
    notifyListeners();
    if (text.isNotEmpty) {
      await submitUserText(text);
    }
  }

  /// Bỏ bản nháp (nói nhầm / nhận diện sai hoàn toàn) — không gửi gì.
  void discardDraft() {
    _draft = null;
    notifyListeners();
  }

  /// Gửi một câu của người học cho AI (public để test được luồng lỗi/chấm điểm).
  @visibleForTesting
  Future<void> submitUserText(String text) async {
    // Thêm bong bóng người dùng + bong bóng AI "đang nghĩ".
    messages.add(ChatMessage(fromUser: true, japanese: text));
    messages.add(ChatMessage.pendingAi());
    _busy = true;
    notifyListeners();

    // Lượt ĐỌC BÀI (thi Nhật 1): tự chấm độ khớp với bài đọc gốc bằng thuật
    // toán rồi gửi kèm cho AI làm neo điểm (thay vì để model tự đoán).
    int? readingMatch;
    if (_scenario.examDrill &&
        _answeredCount == 0 &&
        _scenario.readingPassage != null) {
      readingMatch = readingMatchPercent(text, _scenario.readingPassage!);
    }

    try {
      final turn =
          await _ai.sendUserUtterance(text, readingMatchPercent: readingMatch);
      // Lượt trả lời thành công → tiến độ thi tiến một bước (tính cục bộ).
      if (_scenario.examDrill) {
        _answeredCount++;
        _syncExamState();
      }
      // Gắn điểm phát âm vào bong bóng người dùng vừa thêm.
      final userIndex = messages.length - 2;
      if (turn.pronunciationScore != null) {
        messages[userIndex] = messages[userIndex].copyWith(
          pronunciationScore: turn.pronunciationScore,
        );
      }
      _replacePendingWithAi(turn);
      // Buổi THI vừa hoàn thành → lưu vào lịch sử (kèm điểm từng lượt).
      // Nhớ doc id để nếu người dùng bấm "Xem phân tích" thì gắn thêm vào
      // đúng bản ghi này thay vì tạo bản mới.
      if (_scenario.examDrill && _examFinished) {
        SpeakingHistoryService.saveSession(
          mode: _historyMode,
          title: _scenario.viLabel,
          transcript: List.of(messages),
          score: _examTotalScore(),
          examScores: examTurnScores,
        ).then((id) => _historyDocId = id);
      }
    } catch (e) {
      _failPending(e.toString());
      // Gỡ luôn bong bóng user của lượt lỗi: bảng điểm thi Nhật 1 map điểm
      // theo THỨ TỰ lượt user (examTurnScores) — giữ lại lượt lỗi (score null)
      // sẽ chiếm slot và đẩy lệch điểm mọi lượt sau so với _answeredCount.
      _removeLastUserMessage();
      // Trả câu nói về draft để người dùng chỉ cần bấm gửi lại.
      _draft = text;
    }
    _busy = false;
    notifyListeners();
  }

  /// Gửi TOÀN BỘ hội thoại cho AI PHÂN TÍCH (điểm tổng, điểm mạnh, cần cải
  /// thiện, góp ý từng câu).
  /// - Tự do / JPD316: gọi khi bấm "Kết thúc" — đồng thời khóa mic.
  /// - Thi Nhật 1/2: gọi ĐƯỢC sau khi thi xong (nút "Xem phân tích" cạnh
  ///   bảng điểm); trước đó bị chặn để không cắt ngang bài thi.
  Future<void> endSession() async {
    if (_busy || _listening || _sessionEnded) return;
    if (_scenario.examDrill && !_examFinished) return;
    if (!hasUserTurn) return;
    await _speech.stopSpeaking(); // ngắt TTS đang đọc dở
    _busy = true;
    _analyzing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _ai.analyzeConversation(_formatTranscript());
      if (_disposed) return; // đã thoát màn trong lúc chờ phân tích
      _analysis = result;
      _sessionEnded = true;
      if (_historyDocId != null) {
        // Buổi thi đã có bản ghi lịch sử → chỉ gắn thêm phân tích.
        SpeakingHistoryService.attachAnalysis(
          docId: _historyDocId!,
          analysis: result,
        );
      } else {
        // Buổi hội thoại: lưu buổi luyện + phân tích thành bản ghi mới.
        SpeakingHistoryService.saveSession(
          mode: _historyMode,
          title: _scenario.viLabel,
          transcript: List.of(messages),
          score: result.overallScore,
          analysis: result,
        ).then((id) => _historyDocId = id);
      }
      // Đọc to câu tạm biệt để buổi "gọi điện" kết thúc tự nhiên.
      _speech.speak(result.farewellJp);
    } catch (e) {
      _error = e.toString(); // buổi luyện vẫn tiếp tục, bấm Kết thúc thử lại
    }
    _busy = false;
    _analyzing = false;
    notifyListeners();
  }

  /// Mã chế độ lưu vào lịch sử buổi luyện.
  String get _historyMode {
    switch (_scenario.drillType) {
      case ExamDrillType.nihon1:
        return 'nihon1';
      case ExamDrillType.nihon2:
        return 'nihon2';
      case ExamDrillType.none:
        return _scenario.id.startsWith('exam_') ? 'jpd316' : 'free';
    }
  }

  /// Tổng điểm thi /100 — cùng công thức với ExamResultCard (đọc + câu hỏi
  /// 15đ/câu + tác phong 10đ từ trung bình các lượt).
  int _examTotalScore() {
    final isN2 = _scenario.drillType == ExamDrillType.nihon2;
    final readingMax = isN2 ? 45 : 30;
    final questionCount = isN2 ? 3 : 4;
    final scores = examTurnScores;
    int? at(int i) => i < scores.length ? scores[i] : null;
    final graded = [
      for (var i = 0; i <= questionCount; i++) at(i),
    ].whereType<int>().toList();
    final avg = graded.isEmpty
        ? 0.0
        : graded.reduce((a, b) => a + b) / graded.length;
    var total = ((at(0) ?? 0) * readingMax / 100).round();
    for (var i = 1; i <= questionCount; i++) {
      total += ((at(i) ?? 0) * 15 / 100).round();
    }
    total += (avg * 10 / 100).round();
    return total;
  }

  /// Định dạng hội thoại thành văn bản cho lượt phân tích cuối buổi.
  String _formatTranscript() {
    final buf = StringBuffer();
    for (final m in messages) {
      if (m.isPending || m.japanese.isEmpty) continue;
      buf.writeln(m.fromUser ? 'Học viên: ${m.japanese}' : 'AI: ${m.japanese}');
    }
    return buf.toString();
  }

  /// Luyện lại từ đầu với cùng tình huống (sau khi đã kết thúc buổi luyện).
  Future<void> restart() => selectScenario(_scenario);

  /// Đọc to một câu tiếng Nhật (nút "▶ Nghe").
  Future<void> speak(String japanese) => _speech.speak(japanese);

  /// Suy trạng thái thi từ số lượt SV đã trả lời — nguồn chân lý cục bộ cho
  /// UI (giá trị model tự khai chỉ giúp model bám format, không dùng).
  ///
  /// Nhật 1 (JPD113): 0=đọc bài, 1–3=câu theo tranh, 4=câu tự do, 5=xong.
  /// Nhật 2 (JPD123): 0=đọc bài, 1=câu theo tranh, 2–3=câu không tranh, 4=xong.
  void _syncExamState() {
    switch (_scenario.drillType) {
      case ExamDrillType.none:
        _examPhase = null;
        _examProgress = null;
        _examFinished = false;
      case ExamDrillType.nihon1:
        _examFinished = false;
        if (_answeredCount <= 0) {
          _examPhase = 'reading';
          _examProgress = 'Đọc bài';
        } else if (_answeredCount <= 3) {
          _examPhase = 'picture';
          _examProgress = 'Câu $_answeredCount/4';
        } else if (_answeredCount == 4) {
          _examPhase = 'free';
          _examProgress = 'Câu 4/4';
        } else {
          _examPhase = 'done';
          _examProgress = 'Hoàn thành';
          _examFinished = true;
        }
      case ExamDrillType.nihon2:
        _examFinished = false;
        if (_answeredCount <= 0) {
          _examPhase = 'reading';
          _examProgress = 'Đọc bài';
        } else if (_answeredCount == 1) {
          _examPhase = 'picture'; // đang trả lời câu ① theo tranh
          _examProgress = 'Câu 1/3';
        } else if (_answeredCount <= 3) {
          _examPhase = 'free'; // câu ②③ không tranh
          _examProgress = 'Câu $_answeredCount/3';
        } else {
          _examPhase = 'done';
          _examProgress = 'Hoàn thành';
          _examFinished = true;
        }
    }
  }

  void _replacePendingWithAi(AiTurn turn) {
    // Người dùng đã thoát màn trong lúc AI đang nghĩ → KHÔNG đọc to câu trả
    // lời nữa (bug: thoát ra vẫn nghe tiếng AI).
    if (_disposed) return;
    final i = messages.lastIndexWhere((m) => m.isPending);
    if (i == -1) return;
    messages[i] = ChatMessage(
      fromUser: false,
      japanese: turn.replyJp,
      reading: turn.replyReading,
      translation: turn.replyTranslation,
      feedback: turn.feedback,
    );
    // Tự đọc to câu của AI để người học nghe được ngay (không phải bấm "Nghe").
    _speech.speak(turn.replyJp);
  }

  void _failPending(String message) {
    final i = messages.lastIndexWhere((m) => m.isPending);
    if (i != -1) messages.removeAt(i);
    _error = message;
  }

  /// Gỡ bong bóng user CUỐI CÙNG (lượt vừa gửi nhưng AI trả lỗi).
  void _removeLastUserMessage() {
    final i = messages.lastIndexWhere((m) => m.fromUser);
    if (i != -1) messages.removeAt(i);
  }

  /// Các lời gọi AI/STT là async — có thể hoàn thành SAU khi màn đã đóng.
  /// Notify lúc đó vừa vô nghĩa vừa ném assert của ChangeNotifier.
  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ai.dispose();
    _speech.dispose();
    super.dispose();
  }
}

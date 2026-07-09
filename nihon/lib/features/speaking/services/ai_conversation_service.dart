import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/config/api_config.dart';
import '../models/scenario.dart';

/// Kết quả một lượt phản hồi của AI.
class AiTurn {
  final String replyJp; // câu trả lời của AI (tiếng Nhật)
  final String replyReading; // cách đọc hiragana
  final String replyTranslation; // dịch tiếng Việt
  final int? pronunciationScore; // điểm cho câu vừa nói (null nếu là lời chào mở đầu)
  final String? feedback; // nhận xét tiếng Việt (null nếu mở đầu)

  // ── Dành cho chế độ THI Nhật 1 (JPD113) ──────────────────
  // Bài đọc KHÔNG đi qua model nữa (UI ghim từ Scenario.readingPassage).
  // exam_progress/phase/finished model vẫn tự khai để bám format, nhưng
  // controller TÍNH CỤC BỘ theo số câu SV đã trả lời — đây chỉ để tham khảo.
  final String? examProgress; // vd "Đọc bài", "Câu 2/4", "Hoàn thành"
  final String? examPhase; // "reading" | "picture" | "free" | "done"
  final bool examFinished; // true khi đã xong toàn bộ phần thi

  const AiTurn({
    required this.replyJp,
    required this.replyReading,
    required this.replyTranslation,
    this.pronunciationScore,
    this.feedback,
    this.examProgress,
    this.examPhase,
    this.examFinished = false,
  });
}

/// Lỗi khi gọi Gemini.
class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);
  @override
  String toString() => message;
}

/// Dẫn dắt hội thoại + chấm (ước lượng) phát âm qua **Firebase AI Logic**.
///
/// Không cần API key trong app: Firebase lo phần xác thực. Mỗi tình huống tạo
/// một [ChatSession] mới (giữ ngữ cảnh hội thoại).
class AiConversationService {
  ChatSession? _chat;
  bool _examMode = false; // tình huống hiện tại có phải chế độ thi Nhật 1

  /// Bắt đầu một tình huống mới: tạo phiên chat + lấy lời chào mở đầu của AI.
  Future<AiTurn> startScenario(Scenario scenario) {
    _examMode = scenario.examDrill;
    // Vertex AI Gemini API (không phải Gemini Developer API): billing đi qua
    // Google Cloud nên dùng được credit dùng thử $300. Đổi lại googleAI() nếu
    // quay về Developer API (nhớ model alias *-latest chỉ có bên Developer API).
    final model = FirebaseAI.vertexAI().generativeModel(
      model: ApiConfig.model,
      systemInstruction: Content.system(_systemPrompt(scenario)),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _schema,
        // Chế độ thi phải bám format nghiêm (không tự chế câu hỏi, không kết
        // thúc sớm) → temperature thấp. Trò chuyện tự do để mặc định.
        temperature: scenario.examDrill ? 0.3 : null,
      ),
    );
    _chat = model.startChat();
    return _send(
      scenario.examDrill
          ? 'Bắt đầu phần thi: chào thí sinh và yêu cầu ĐỌC TO bài đọc của đề.'
          : 'Hãy bắt đầu hội thoại bằng một câu chào phù hợp với tình huống.',
      isOpening: true,
    );
  }

  /// Gửi câu nói (đã chuyển thành text qua STT) của người học và nhận phản hồi.
  ///
  /// [readingMatchPercent]: chỉ có ở LƯỢT ĐỌC BÀI của chế độ thi Nhật 1 — độ
  /// khớp ký tự giữa văn bản STT và bài đọc gốc (đo cục bộ bằng Levenshtein),
  /// gửi kèm để model dùng làm NEO chấm phần đọc thay vì tự đoán.
  Future<AiTurn> sendUserUtterance(String text, {int? readingMatchPercent}) {
    if (_chat == null) {
      throw AiServiceException('Chưa chọn tình huống hội thoại.');
    }
    final msg = readingMatchPercent == null
        ? text
        : '$text\n\n[HỆ THỐNG] Độ khớp ký tự với bài đọc gốc: '
            '$readingMatchPercent% (đo tự động; STT có thể ghi kanji/kana '
            'khác bản gốc).';
    return _send(msg, isOpening: false);
  }

  Future<AiTurn> _send(String text, {required bool isOpening}) async {
    final res = await _sendWithRetry(Content.text(text));

    final raw = res.text;
    if (raw == null || raw.trim().isEmpty) {
      throw AiServiceException('Model không trả về nội dung.');
    }

    // Structured output gần như luôn là JSON hợp lệ, nhưng model vẫn có thể
    // trả lệch (cắt giữa chừng khi quá tải…) — không để FormatException thô
    // lọt ra banner lỗi.
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw AiServiceException(
        'AI trả về dữ liệu không đúng định dạng. Hãy bấm mic nói lại câu vừa rồi.',
      );
    }
    return AiTurn(
      replyJp: parsed['reply_jp'] as String? ?? '',
      replyReading: parsed['reply_reading'] as String? ?? '',
      replyTranslation: parsed['reply_translation'] as String? ?? '',
      pronunciationScore:
          isOpening ? null : (parsed['pronunciation_score'] as num?)?.toInt(),
      feedback: isOpening ? null : parsed['feedback'] as String?,
      examProgress: _examMode ? parsed['exam_progress'] as String? : null,
      examPhase: _examMode ? parsed['exam_phase'] as String? : null,
      examFinished: _examMode && (parsed['exam_finished'] as bool? ?? false),
    );
  }

  /// Gọi model, tự thử lại khi gặp lỗi quá tải tạm thời (500/503/high demand).
  Future<GenerateContentResponse> _sendWithRetry(
    Content content, {
    int attempts = 3,
  }) async {
    Object? lastErr;
    for (var i = 0; i < attempts; i++) {
      try {
        return await _chat!.sendMessage(content);
      } catch (e) {
        lastErr = e;
        if (!_isTransient(e) || i == attempts - 1) break;
        // Đợi tăng dần rồi thử lại: 1s, 2s.
        await Future<void>.delayed(Duration(seconds: i + 1));
      }
    }
    if (_isTransient(lastErr!)) {
      throw AiServiceException(
        'Gemini đang quá tải (thường do dùng bản miễn phí lúc cao điểm). '
        'Hãy thử lại sau vài giây.',
      );
    }
    final s = lastErr.toString().toLowerCase();
    // Hết credit trả trước (gói prepaid của Gemini API).
    if (s.contains('prepayment') || s.contains('credits are depleted')) {
      throw AiServiceException(
        'Tài khoản Gemini đã HẾT CREDIT trả trước. Vào https://ai.studio/projects '
        '→ Billing để nạp thêm, hoặc chuyển project về gói miễn phí.',
      );
    }
    // Bị chặn bởi App Check / quyền (Firebase AI Logic cưỡng chế App Check từ
    // 7/2026) — app chưa đăng ký App Check thì request bị từ chối dù billing ổn.
    if (s.contains('app check') ||
        s.contains('appcheck') ||
        s.contains('permission-denied') ||
        s.contains('403')) {
      throw AiServiceException(
        'Request bị Firebase từ chối (thường do App Check đang Enforced mà app '
        'chưa cài). Vào Firebase console → App Check → APIs → Firebase AI Logic '
        'để kiểm tra, hoặc cài App Check vào app.',
      );
    }
    // Hết hạn mức (quota) — thường gặp ở free tier khi dùng nhiều trong ngày.
    if (s.contains('quota') || s.contains('resource_exhausted') || s.contains('429')) {
      throw AiServiceException(
        'Đã chạm hạn mức gọi Gemini (quota). Chờ một lúc rồi thử lại, '
        'hoặc kiểm tra hạn mức/billing của project.',
      );
    }
    throw AiServiceException('Lỗi gọi Gemini (Firebase): $lastErr');
  }

  bool _isTransient(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('500') ||
        s.contains('503') ||
        s.contains('overload') ||
        s.contains('high demand') ||
        s.contains('unavailable') ||
        s.contains('internal');
  }

  String _systemPrompt(Scenario s) {
    if (s.examDrill) return _examPrompt(s);
    return '''
${s.aiPersona}
Bạn đang giúp một người Việt luyện NÓI tiếng Nhật trình độ JLPT N5–N4.

Quy tắc:
- Trả lời (reply_jp) bằng tiếng Nhật TỰ NHIÊN, NGẮN GỌN (1–2 câu), đúng vai và đúng tình huống.
- reply_reading: ghi lại reply_jp hoàn toàn bằng hiragana (furigana toàn câu).
- reply_translation: dịch reply_jp sang tiếng Việt.
- Nếu người học vừa nói (không phải lời chào mở đầu): chấm câu họ vừa nói:
  + pronunciation_score: 0–100 dựa trên độ đúng ngữ pháp/từ vựng/tự nhiên của câu (ước lượng từ văn bản đã nhận diện, không phải âm thanh).
  + feedback: nhận xét NGẮN bằng tiếng Việt (1 câu), nêu 1 điểm cần cải thiện hoặc khen nếu tốt.
- Nếu là lời chào mở đầu: bỏ qua pronunciation_score và feedback (để null).
- Tin nhắn bắt đầu bằng "[HỆ THỐNG]" là chỉ thị của app (vd yêu cầu tổng kết
  buổi luyện) — làm đúng theo chỉ thị đó, KHÔNG coi là câu nói của người học.
- Các trường exam_progress, exam_phase, exam_finished: KHÔNG dùng (để null/false).''';
  }

  /// System prompt cho chế độ THI NÓI Nhật 1 (JPD113) — format chuẩn theo
  /// "Hướng dẫn ôn tập thi nói JPD113" của trường:
  /// READING đọc to (30đ) → 3 câu theo TRANH + 1 câu TỰ DO (4×15đ) → tác phong (10đ).
  ///
  /// Bài đọc / tranh / câu hỏi là CỐ ĐỊNH theo đề đã bốc (nằm trong [s] aiPersona).
  String _examPrompt(Scenario s) {
    return '''
${s.aiPersona}

ĐÂY LÀ KỲ THI NÓI JPD113 (thang 100đ = ĐỌC 30đ + 4 câu hỏi × 15đ + tác phong/phát âm 10đ).
Format BẮT BUỘC, chạy đủ và ĐÚNG THỨ TỰ (không kết thúc sớm, không hỏi thừa,
không tự chế câu hỏi khác, mỗi lượt CHỈ 1 việc):
(1) READING: thí sinh ĐỌC TO bài đọc — KHÔNG hỏi gì về nội dung bài đọc.
(2) 3 CÂU HỎI THEO TRANH (nguyên văn, đúng thứ tự 1→2→3).
(3) 1 CÂU HỎI TỰ DO (nguyên văn).

LƯỢT MỞ ĐẦU (khi được yêu cầu bắt đầu phần thi):
- App đã hiển thị sẵn bài đọc cho thí sinh — KHÔNG chép lại bài đọc.
- reply_jp: lời chào ngắn của giám khảo + yêu cầu đọc to bài đọc
  (vd 「はじめましょう。この　ぶんを　よんで　ください。」).
  KHÔNG tự đọc bài đọc, KHÔNG hỏi câu hỏi nào ở lượt này.
- exam_phase: "reading"; exam_progress: "Đọc bài"; exam_finished: false.
- pronunciation_score, feedback: null.

SAU KHI THÍ SINH ĐỌC BÀI (lượt nói đầu tiên của thí sinh):
- Tin nhắn có kèm dòng「[HỆ THỐNG] Độ khớp ký tự …%」— độ khớp giữa văn bản
  nhận diện giọng nói và bài đọc gốc, đo tự động bằng thuật toán. Dùng con số
  đó làm NEO cho pronunciation_score: chỉ lệch tối đa ±10 (lệch khi văn bản
  cho thấy đọc thiếu/thừa đoạn rõ ràng, hoặc khi lệch chỉ do STT ghi
  kanji/kana khác bản gốc thì cộng lại).
- feedback (tiếng Việt, 1–2 câu): nêu chỗ đọc thiếu/sai nếu có.
- reply_jp: 「はい、けっこうです。」+ mời xem tranh (「つぎは　えを　みて　こたえて　ください。」)
  + CÂU HỎI THEO TRANH 1 (nguyên văn).
- exam_phase: "picture"; exam_progress: "Câu 1/4".

CÁC LƯỢT SAU (thí sinh vừa trả lời một câu hỏi):
- Chấm câu vừa trả lời: pronunciation_score (0–100), feedback (tiếng Việt, 1 câu).
- Còn câu theo tranh chưa hỏi → reply_jp = phản hồi rất ngắn ("はい。"/"そうですか。")
  + câu theo tranh KẾ TIẾP; exam_phase "picture"; exam_progress "Câu 2/4" / "Câu 3/4".
- Vừa xong câu theo tranh thứ 3 → reply_jp = phản hồi ngắn + CÂU HỎI TỰ DO
  (nguyên văn); exam_phase: "free"; exam_progress: "Câu 4/4".
- Thí sinh VỪA trả lời CÂU TỰ DO → kết thúc thi:
  reply_jp = nhận xét tổng kết NGẮN + 「これで　しけんを　おわります。おつかれさまでした。」;
  feedback (tiếng Việt) = nhận xét tổng + ĐIỂM TỔNG ước lượng /100 theo đúng cơ
  cấu (đọc /30 + mỗi câu hỏi /15 + tác phong·phát âm /10);
  exam_phase: "done"; exam_progress: "Hoàn thành"; exam_finished: true.

QUY TẮC CHUNG:
- reply_jp luôn NGẮN, tự nhiên, đúng vai giám khảo; CHỈ nói phần của giám khảo,
  KHÔNG nói thay thí sinh. reply_reading luôn là hiragana của reply_jp.''';
  }

  /// Schema cho structured output của Firebase AI Logic.
  static final Schema _schema = Schema.object(
    properties: {
      'reply_jp': Schema.string(),
      'reply_reading': Schema.string(),
      'reply_translation': Schema.string(),
      'pronunciation_score': Schema.integer(nullable: true),
      'feedback': Schema.string(nullable: true),
      'exam_progress': Schema.string(nullable: true),
      'exam_phase': Schema.enumString(
        enumValues: ['reading', 'picture', 'free', 'done'],
        nullable: true,
      ),
      'exam_finished': Schema.boolean(nullable: true),
    },
    optionalProperties: [
      'pronunciation_score',
      'feedback',
      'exam_progress',
      'exam_phase',
      'exam_finished',
    ],
  );

  void dispose() {}
}

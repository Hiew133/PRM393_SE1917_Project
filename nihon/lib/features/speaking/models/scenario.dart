/// "Tranh" của phần TALKING (WITH PICTURES) trong thi Nhật 1 — thể hiện bằng
/// emoji + các dòng gợi ý (thay cho tờ tranh giấy trong phòng thi; SV nhìn
/// thông tin trên tranh để trả lời câu hỏi của giám khảo).
class ExamPicture {
  final String emoji; // hình đại diện to (thay tranh)
  final String caption; // nhãn tranh, vd "アリさん"
  final List<String> hints; // thông tin ghi trên tranh

  const ExamPicture({
    required this.emoji,
    required this.caption,
    required this.hints,
  });
}

/// Một tình huống hội thoại AI.
class Scenario {
  final String id;
  final String emoji;
  final String jpLabel; // カフェ
  final String viLabel; // Quán cà phê
  final String aiPersona; // mô tả vai của AI để đưa vào system prompt

  /// true → chế độ THI NÓI Nhật 1 (JPD113): AI là giám khảo, chạy hết format
  /// "đọc to bài đọc + 3 câu theo tranh + 1 câu tự do" (xem
  /// [ai_conversation_service]).
  final bool examDrill;

  /// Tranh của phần câu hỏi theo tranh (chỉ có ở chế độ thi Nhật 1).
  final ExamPicture? examPicture;

  /// Bài đọc phần READING + bản dịch (chỉ có ở chế độ thi Nhật 1). UI ghim thẻ
  /// bài đọc từ đây — bản gốc trong máy, KHÔNG nhờ AI chép lại (tránh sai chữ).
  final String? readingPassage;
  final String? readingPassageVi;

  const Scenario({
    required this.id,
    required this.emoji,
    required this.jpLabel,
    required this.viLabel,
    required this.aiPersona,
    this.examDrill = false,
    this.examPicture,
    this.readingPassage,
    this.readingPassageVi,
  });
}

const List<Scenario> kScenarios = [
  Scenario(
    id: 'free',
    emoji: '💬',
    jpLabel: '自由会話',
    viLabel: 'Trò chuyện tự do',
    aiPersona:
        'Bạn là một người bạn Nhật thân thiện, trò chuyện tự do với người học '
        'bằng tiếng Nhật về các chủ đề đời thường (sở thích, công việc, thời '
        'tiết, du lịch…). Hãy chủ động hỏi lại để duy trì hội thoại.',
  ),
];

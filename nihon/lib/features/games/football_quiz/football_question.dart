/// Một câu hỏi ngữ pháp cho trò chơi "Thủ môn bắt bóng".
///
/// Câu hỏi được VIẾT CỨNG (không tải Firestore) để mở trò chơi tức thì,
/// không lag. Nội dung bám sát 6 mẫu ngữ pháp N5 mà app đang dạy
/// (は・です・と・の・じゃありません・か・từ để hỏi) — xem [kGrammarPoints].
class FootballQuestion {
  /// Câu tiếng Nhật có chỗ trống (đánh dấu bằng '＿＿＿').
  final String sentence;

  /// Nghĩa / gợi ý tiếng Việt của câu.
  final String hintVi;

  /// 4 đáp án.
  final List<String> options;

  /// Vị trí đáp án đúng trong [options].
  final int correctIndex;

  /// Giải thích ngắn khi trả lời xong.
  final String explain;

  const FootballQuestion({
    required this.sentence,
    required this.hintVi,
    required this.options,
    required this.correctIndex,
    required this.explain,
  });

  String get correctAnswer => options[correctIndex];
}

/// Ngân hàng câu hỏi (viết cứng). Mỗi ván bốc ngẫu nhiên N câu.
const List<FootballQuestion> kFootballQuestions = [
  FootballQuestion(
    sentence: 'わたし＿＿＿がくせいです。',
    hintVi: 'Tôi là học sinh.',
    options: ['は', 'を', 'の', 'と'],
    correctIndex: 0,
    explain: 'は là trợ từ chủ đề: "A は B です" (A thì là B).',
  ),
  FootballQuestion(
    sentence: 'これは にほんご＿＿＿ ほんです。',
    hintVi: 'Đây là sách tiếng Nhật.',
    options: ['の', 'は', 'と', 'を'],
    correctIndex: 0,
    explain: 'の nối 2 danh từ: N1 の N2 (sách "của" tiếng Nhật).',
  ),
  FootballQuestion(
    sentence: 'しゅみは サッカー＿＿＿ どくしょです。',
    hintVi: 'Sở thích là bóng đá và đọc sách.',
    options: ['と', 'の', 'は', 'か'],
    correctIndex: 0,
    explain: 'と dùng để liệt kê danh từ: N1 と N2 (… và …).',
  ),
  FootballQuestion(
    sentence: 'わたしは がくせい＿＿＿。',
    hintVi: 'Tôi KHÔNG phải là học sinh.',
    options: ['じゃありません', 'です', 'ですか', 'の'],
    correctIndex: 0,
    explain: 'じゃありません là dạng phủ định của です.',
  ),
  FootballQuestion(
    sentence: 'パクさんは がくせいです＿＿＿。',
    hintVi: 'Bạn Park có phải là sinh viên không?',
    options: ['か', 'の', 'と', 'は'],
    correctIndex: 0,
    explain: 'Thêm か cuối câu để tạo câu hỏi Yes/No.',
  ),
  FootballQuestion(
    sentence: 'あなたの なまえは ＿＿＿ですか。',
    hintVi: 'Tên của bạn là gì?',
    options: ['なん', 'だれ', 'どこ', 'いくら'],
    correctIndex: 0,
    explain: 'なん(何) = "gì", hỏi tên/sự vật.',
  ),
  FootballQuestion(
    sentence: 'これは ＿＿＿ですか。ごひゃくえんです。',
    hintVi: 'Cái này bao nhiêu tiền? — 500 yên.',
    options: ['いくら', 'いつ', 'どこ', 'だれ'],
    correctIndex: 0,
    explain: 'いくら = "bao nhiêu tiền".',
  ),
  FootballQuestion(
    sentence: 'Aさんは FPT＿＿＿ しゃいんです。',
    hintVi: 'Bạn A là nhân viên của FPT.',
    options: ['の', 'と', 'は', 'を'],
    correctIndex: 0,
    explain: 'の chỉ sự trực thuộc: nhân viên "của" FPT.',
  ),
  FootballQuestion(
    sentence: 'そちらは ＿＿＿ですか。',
    hintVi: 'Đó là ai vậy?',
    options: ['だれ', 'なに', 'どこ', 'いくら'],
    correctIndex: 0,
    explain: 'だれ(誰) = "ai", hỏi về người.',
  ),
  FootballQuestion(
    sentence: 'カルロスさんは ＿＿＿ですか。２５さいです。',
    hintVi: 'Bạn Carlos bao nhiêu tuổi? — 25 tuổi.',
    options: ['なんさい', 'なんじ', 'どこ', 'いくら'],
    correctIndex: 0,
    explain: 'なんさい(何歳) = "mấy tuổi".',
  ),
  FootballQuestion(
    sentence: 'わたしは Sonです。Sonさん＿＿＿ がくせいです。',
    hintVi: 'Tôi là Sơn. Bạn Sơn là sinh viên.',
    options: ['は', 'を', 'の', 'か'],
    correctIndex: 0,
    explain: 'は nêu chủ đề của câu.',
  ),
  FootballQuestion(
    sentence: 'きょうしつは ＿＿＿ですか。にかいです。',
    hintVi: 'Phòng học ở đâu? — Ở tầng 2.',
    options: ['どこ', 'いつ', 'だれ', 'なん'],
    correctIndex: 0,
    explain: 'どこ = "ở đâu", hỏi địa điểm.',
  ),
  FootballQuestion(
    sentence: 'これは ほん＿＿＿ありません。ノートです。',
    hintVi: 'Đây không phải sách. Là quyển vở.',
    options: ['じゃ', 'は', 'の', 'と'],
    correctIndex: 0,
    explain: '本じゃありません = "không phải là sách".',
  ),
  FootballQuestion(
    sentence: 'たんじょうびは ＿＿＿ですか。',
    hintVi: 'Sinh nhật là khi nào?',
    options: ['いつ', 'どこ', 'なん', 'だれ'],
    correctIndex: 0,
    explain: 'いつ = "khi nào", hỏi thời gian.',
  ),
];

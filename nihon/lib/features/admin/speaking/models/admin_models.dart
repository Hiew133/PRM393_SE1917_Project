/// Các model cho phần Admin thi Nói (JPD316).
///
/// Cấu trúc đề chuẩn JPD316: tổng 100đ = 会話 (Hội thoại) 55đ + Q&A 45đ.
library;

enum ExamStatus { published, draft, archived }

extension ExamStatusInfo on ExamStatus {
  String get label => switch (this) {
        ExamStatus.published => 'Xuất bản',
        ExamStatus.draft => 'Nháp',
        ExamStatus.archived => 'Lưu trữ',
      };
}

/// Nhóm câu hỏi Q&A: 1 = có tranh, 2 = không tranh, 3 = tự do.
enum QaGroup { withImage, noImage, free }

extension QaGroupInfo on QaGroup {
  int get number => index + 1;
  String get label => switch (this) {
        QaGroup.withImage => 'Câu hỏi có tranh',
        QaGroup.noImage => 'Câu hỏi không tranh',
        QaGroup.free => 'Câu hỏi tự do',
      };
  String get emoji => switch (this) {
        QaGroup.withImage => '🖼',
        QaGroup.noImage => '💬',
        QaGroup.free => '⚡',
      };
}

/// Một câu trong 質問リスト (Q&A). Thuộc về một đề ([examId]).
class QaQuestion {
  final String id; // doc id, vd "final_a__q1"
  String examId; // đề chứa câu này
  int order; // thứ tự hiển thị
  QaGroup group;
  String lesson; // vd "課1"
  String grammar; // mẫu ngữ pháp muốn khai thác, vd "〜において／〜における"
  String prompt; // câu hỏi (tiếng Nhật)
  String? propType; // loại tranh/ngữ liệu: 新聞記事 / 天気予報 / チラシ / イラスト ...
  String? imageUrl; // ảnh tranh (Firebase Storage) — chỉ nhóm có tranh

  QaQuestion({
    required this.id,
    required this.examId,
    required this.order,
    required this.group,
    required this.lesson,
    required this.grammar,
    required this.prompt,
    this.propType,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'examId': examId,
        'order': order,
        'group': group.name,
        'lesson': lesson,
        'grammar': grammar,
        'prompt': prompt,
        'propType': propType,
        'imageUrl': imageUrl,
      };

  factory QaQuestion.fromMap(String id, Map<String, dynamic> m) => QaQuestion(
        id: id,
        examId: (m['examId'] ?? '') as String,
        order: (m['order'] ?? 0) as int,
        group: QaGroup.values
            .firstWhere((g) => g.name == m['group'], orElse: () => QaGroup.noImage),
        lesson: (m['lesson'] ?? '') as String,
        grammar: (m['grammar'] ?? '') as String,
        prompt: (m['prompt'] ?? '') as String,
        propType: m['propType'] as String?,
        imageUrl: m['imageUrl'] as String?,
      );
}

/// Một lượt thoại trong 会話 mẫu.
class DialogueLine {
  final String role; // 'S' = sinh viên, 'T' = giảng viên
  final String text;
  const DialogueLine(this.role, this.text);
}

/// Một tình huống 会話 (biến thể từ 1 mẫu gốc trong giáo trình). Thuộc 1 đề.
class ConversationSituation {
  final String id; // doc id, vd "final_a__s11_1"
  String examId; // đề chứa tình huống này
  String baseTemplate; // mẫu gốc, vd "会話3.1"
  String title; // mô tả ngắn (tiếng Việt)
  List<String> grammar; // 文法 bắt buộc
  String changeNote; // chi tiết có thể đổi
  String scenarioStudent; // 場面 cho SV (tiếng Nhật)
  String scenarioTeacher; // 場面 cho giảng viên (tiếng Nhật)
  List<DialogueLine> sample; // 会話 mẫu
  bool drafted; // đã soạn xong chưa

  ConversationSituation({
    required this.id,
    required this.examId,
    required this.baseTemplate,
    required this.title,
    this.grammar = const [],
    this.changeNote = '',
    this.scenarioStudent = '',
    this.scenarioTeacher = '',
    this.sample = const [],
    this.drafted = false,
  });

  Map<String, dynamic> toMap() => {
        'examId': examId,
        'baseTemplate': baseTemplate,
        'title': title,
        'grammar': grammar,
        'changeNote': changeNote,
        'scenarioStudent': scenarioStudent,
        'scenarioTeacher': scenarioTeacher,
        'sample': sample.map((l) => {'role': l.role, 'text': l.text}).toList(),
        'drafted': drafted,
      };

  factory ConversationSituation.fromMap(String id, Map<String, dynamic> m) =>
      ConversationSituation(
        id: id,
        examId: (m['examId'] ?? '') as String,
        baseTemplate: (m['baseTemplate'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        grammar: ((m['grammar'] as List?) ?? const []).cast<String>(),
        changeNote: (m['changeNote'] ?? '') as String,
        scenarioStudent: (m['scenarioStudent'] ?? '') as String,
        scenarioTeacher: (m['scenarioTeacher'] ?? '') as String,
        sample: ((m['sample'] as List?) ?? const [])
            .map((e) => DialogueLine(
                (e['role'] ?? 'S') as String, (e['text'] ?? '') as String))
            .toList(),
        drafted: (m['drafted'] ?? false) as bool,
      );
}

/// Một đề thi Nói.
class Exam {
  final String id;
  String title;
  String lessonRange; // vd "Bài 1~5"
  ExamStatus status;
  String updatedLabel; // vd "2 ngày trước"
  int studentsTaken;
  int avgScore;

  // Cấu trúc chuẩn JPD316 (điểm/thời gian cố định, có thể chỉnh sau).
  final int conversationPoints; // 55
  final int qaPoints; // 45
  final int conversationMinutes; // 4
  final int qaMinutes; // 4
  final int conversationPrepSeconds; // 30 (chuẩn bị tại chỗ khi bốc)
  final int prepMinutes; // 2 (gọi SV, nhập điểm)
  final int situationTarget; // 1 tình huống/đề (biến thể lấy từ nhiều đề)

  Exam({
    required this.id,
    required this.title,
    required this.lessonRange,
    this.status = ExamStatus.draft,
    this.updatedLabel = '',
    this.studentsTaken = 0,
    this.avgScore = 0,
    this.conversationPoints = 55,
    this.qaPoints = 45,
    this.conversationMinutes = 4,
    this.qaMinutes = 4,
    this.conversationPrepSeconds = 30,
    this.prepMinutes = 2,
    this.situationTarget = 1,
  });

  int get totalPoints => conversationPoints + qaPoints;

  Map<String, dynamic> toMap() => {
        'title': title,
        'lessonRange': lessonRange,
        'status': status.name,
        'updatedLabel': updatedLabel,
        'studentsTaken': studentsTaken,
        'avgScore': avgScore,
      };

  factory Exam.fromMap(String id, Map<String, dynamic> m) => Exam(
        id: id,
        title: (m['title'] ?? '') as String,
        lessonRange: (m['lessonRange'] ?? 'Bài 1~5') as String,
        status: ExamStatus.values
            .firstWhere((e) => e.name == m['status'], orElse: () => ExamStatus.draft),
        updatedLabel: (m['updatedLabel'] ?? '') as String,
        studentsTaken: (m['studentsTaken'] ?? 0) as int,
        avgScore: (m['avgScore'] ?? 0) as int,
      );
}

/// Một tiêu chí chấm điểm (dùng ở màn chấm thi S06).
class RubricCriterion {
  final String id;
  final String label;
  final String hint;
  final int maxPoints;
  final QaGroup? qaGroup; // null nếu thuộc phần 会話

  const RubricCriterion({
    required this.id,
    required this.label,
    required this.maxPoints,
    this.hint = '',
    this.qaGroup,
  });
}

/// Điểm một sinh viên trong một đề (kết quả chấm thi S06).
class StudentScore {
  final String id; // doc id
  String examId;
  String studentName;
  String studentId; // MSV
  String? situationId; // tình huống 会話 đã bốc
  Map<String, int> criteria; // id tiêu chí -> điểm
  String note; // ghi chú cho SV
  int total; // tổng điểm (cache)
  int createdAtMs;

  StudentScore({
    required this.id,
    required this.examId,
    this.studentName = '',
    this.studentId = '',
    this.situationId,
    Map<String, int>? criteria,
    this.note = '',
    this.total = 0,
    this.createdAtMs = 0,
  }) : criteria = criteria ?? {};

  Map<String, dynamic> toMap() => {
        'examId': examId,
        'studentName': studentName,
        'studentId': studentId,
        'situationId': situationId,
        'criteria': criteria,
        'note': note,
        'total': total,
        'createdAtMs': createdAtMs,
      };

  factory StudentScore.fromMap(String id, Map<String, dynamic> m) => StudentScore(
        id: id,
        examId: (m['examId'] ?? '') as String,
        studentName: (m['studentName'] ?? '') as String,
        studentId: (m['studentId'] ?? '') as String,
        situationId: m['situationId'] as String?,
        criteria: ((m['criteria'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, (v ?? 0) as int)),
        note: (m['note'] ?? '') as String,
        total: (m['total'] ?? 0) as int,
        createdAtMs: (m['createdAtMs'] ?? 0) as int,
      );
}

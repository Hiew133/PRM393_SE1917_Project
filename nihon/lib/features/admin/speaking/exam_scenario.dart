import '../../speaking/models/scenario.dart';
import 'models/admin_models.dart';

/// Dựng [Scenario] cho màn Luyện nói từ một tình huống 会話 ([ConversationSituation]).
///
/// AI đóng vai GIẢNG VIÊN theo 場面 GV; 会話 mẫu được đưa vào như **khung tham
/// khảo lỏng** (bám trình tự & vai nhưng ứng biến tự nhiên theo lời SV, KHÔNG
/// đọc đúng từng chữ). Mục tiêu cốt lõi: SV dùng được các mẫu 文法 yêu cầu và
/// giải quyết tình huống. Dùng chung cho S07 (bốc đề) và màn luyện phía SV.
Scenario buildExamScenario(ConversationSituation s) {
  final grammar = s.grammar.isEmpty
      ? ''
      : '\nMẫu ngữ pháp SV CẦN dùng (mục tiêu chính): ${s.grammar.join("、")}. '
          'Hãy dẫn dắt sao cho SV có cơ hội tự nhiên dùng các mẫu này; nếu mãi '
          'chưa dùng thì gợi mở khéo, KHÔNG nhắc thẳng tên mẫu.';

  final flow = s.sample.isEmpty
      ? ''
      : '\n\n会話 mẫu (KHUNG THAM KHẢO — bám trình tự & vai, KHÔNG đọc đúng '
          'từng chữ; 「＿＿」 là chỗ chi tiết có thể thay đổi tuỳ SV):\n'
          '${s.sample.map((l) => '${l.role == "S" ? "SV" : "GV(bạn)"}: ${l.text}').join("\n")}';

  return Scenario(
    id: 'exam_${s.id}',
    emoji: '🎓',
    jpLabel: s.baseTemplate,
    viLabel: s.title,
    aiPersona:
        'Bạn là GIẢNG VIÊN đang chấm thi NÓI tiếng Nhật (JPD316), đóng vai '
        'người đối thoại (vai GV) trong tình huống 会話: "${s.title}".\n'
        'Vai của bạn (場面 giảng viên): '
        '${s.scenarioTeacher.isEmpty ? "(ứng biến hợp lý theo tình huống)" : s.scenarioTeacher}\n'
        'Bối cảnh của sinh viên: '
        '${s.scenarioStudent.isEmpty ? "(theo tình huống)" : s.scenarioStudent}\n'
        'Cách dẫn: bám trình tự chung của 会話 mẫu nhưng PHẢN HỒI TỰ NHIÊN theo '
        'đúng những gì SV vừa nói (không cần khớp 100%). Chỉ nói phần của GV, '
        'KHÔNG nói thay lời SV.$grammar$flow',
  );
}

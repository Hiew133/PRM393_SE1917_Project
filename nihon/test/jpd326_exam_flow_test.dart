// Luồng thi Nhật 5 (JPD326): role-play nhiều lượt → câu hỏi 1 → câu hỏi 2 →
// hoàn thành, và quy điểm về thang 60/20/10/10 của trường.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:nihon/features/speaking/models/jpd326_exam_sets.dart';
import 'package:nihon/features/speaking/models/scenario.dart';
import 'package:nihon/features/speaking/services/ai_conversation_service.dart';
import 'package:nihon/features/speaking/speaking_controller.dart';

import 'speaking_fakes.dart';

/// AI giả chạy đúng format JPD326: 3 lượt role-play rồi hỏi câu 1, câu 2, xong.
class _FakeJpd326Ai extends FakeAi {
  int _userTurns = 0;

  /// Điểm trả về theo thứ tự lượt (role-play ×3, câu 1, câu 2).
  final List<int> turnScores;
  _FakeJpd326Ai(this.turnScores);

  @override
  Future<AiTurn> startScenario(Scenario scenario) async => const AiTurn(
        replyJp: 'では、始めましょう。',
        replyReading: 'では、はじめましょう。',
        replyTranslation: 'Bắt đầu nhé.',
        examPhase: 'roleplay',
        examProgress: 'Role-play',
      );

  @override
  Future<AiTurn> sendUserUtterance(String text,
      {int? readingMatchPercent}) async {
    final score = turnScores[_userTurns.clamp(0, turnScores.length - 1)];
    _userTurns++;
    // 3 lượt đầu là role-play; lượt 4 = trả lời câu 1; lượt 5 = trả lời câu 2.
    final String phase;
    final bool finished;
    if (_userTurns < 3) {
      phase = 'roleplay';
      finished = false;
    } else if (_userTurns == 3) {
      phase = 'q1'; // vừa chốt role-play, chuyển sang hỏi câu 1
      finished = false;
    } else if (_userTurns == 4) {
      phase = 'q2';
      finished = false;
    } else {
      phase = 'done';
      finished = true;
    }
    return AiTurn(
      replyJp: 'はい。',
      replyReading: 'はい。',
      replyTranslation: 'Vâng.',
      pronunciationScore: score,
      feedback: 'Tốt.',
      examPhase: phase,
      examFinished: finished,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bốc đề: gán vai A/B, 2 câu hỏi khác nhau', () {
    final exam = Jpd326Exam.draw(Random(42));
    expect(kJpd326Scenes, contains(exam.scene));
    expect(exam.question1.no, isNot(exam.question2.no));
    // Vai của AI luôn ngược vai thí sinh.
    expect(exam.aiRoleLabel, isNot(exam.studentRoleLabel));
    expect(exam.studentRoleText,
        exam.studentIsA ? exam.scene.roleA : exam.scene.roleB);
  });

  test('scenario mang đủ thẻ vai + đúng drill type', () {
    final s = Jpd326Exam.forScene(kJpd326Scenes[2], Random(1)).toScenario();
    expect(s.drillType, ExamDrillType.jpd326);
    expect(s.rolePlayCard, isNotNull);
    expect(s.rolePlayRoleLabel, anyOf('A', 'B'));
    expect(s.aiPersona, contains('CÂU HỎI 1'));
    expect(s.aiPersona, contains('CÂU HỎI 2'));
  });

  test('role-play → câu 1 → câu 2 → hoàn thành, điểm quy đúng thang', () async {
    final exam = Jpd326Exam.forScene(kJpd326Scenes[0], Random(7));
    // 3 lượt role-play đều 80đ, câu 1 = 90đ, câu 2 = 60đ.
    final ai = _FakeJpd326Ai([80, 80, 80, 90, 60]);
    final c = SpeakingController(
        ai: ai, speech: FakeSpeech(), initialScenario: exam.toScenario());
    await c.selectScenario(exam.toScenario());
    expect(c.examPhase, 'roleplay');
    expect(c.examProgress, 'Role-play');

    await c.submitUserText('こんにちは。');
    await c.submitUserText('そうですね。');
    expect(c.examPhase, 'roleplay');

    await c.submitUserText('わかりました。'); // chốt role-play → giám khảo hỏi câu 1
    expect(c.examPhase, 'q1');
    expect(c.examProgress, 'Câu hỏi 1/2');
    expect(c.examFinished, false);

    await c.submitUserText('私はハノイに住んでいます。'); // trả lời câu 1
    expect(c.examPhase, 'q2');
    expect(c.examProgress, 'Câu hỏi 2/2');

    await c.submitUserText('好きな言葉は「ありがとう」です。'); // trả lời câu 2 → hết
    expect(c.examPhase, 'done');
    expect(c.examFinished, true);

    // role-play: 3 lượt 80đ → 80% × 60 = 48
    // câu 1: 90% × 20 = 18 ; câu 2: 60% × 10 = 6
    // thể hiện: trung bình (80+80+80+90+60)/5 = 78 → 78% × 10 = 8
    final b = c.jpd326Breakdown();
    expect(b.rolePlay, 48);
    expect(b.q1, 18);
    expect(b.q2, 6);
    expect(b.delivery, 8);
    expect(b.total, 80);
    c.dispose();
  });
}

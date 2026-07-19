// Test cho SpeakingController với AI/Speech giả — tập trung vào các luồng lỗi
// từng gây bug: lượt gửi lỗi làm lệch bảng điểm thi, và race khi chốt mic.

import 'package:flutter_test/flutter_test.dart';

import 'package:nihon/features/speaking/models/scenario.dart';
import 'package:nihon/features/speaking/speaking_controller.dart';

import 'speaking_fakes.dart';

const _examScenario = Scenario(
  id: 'nihon1_test',
  emoji: '🟢',
  jpLabel: '日本語１',
  viLabel: 'Đề test',
  aiPersona: 'Giám khảo test.',
  drillType: ExamDrillType.nihon1,
  readingPassage: 'たなかさんは　がくせいです。',
  readingPassageVi: 'Tanaka là học sinh.',
);

const _nihon2Scenario = Scenario(
  id: 'nihon2_test',
  emoji: '🔵',
  jpLabel: '日本語２',
  viLabel: 'Đề test Nhật 2',
  aiPersona: 'Giám khảo JPD123 test.',
  drillType: ExamDrillType.nihon2,
  readingPassage: 'わたしは　がくせいです。',
  readingPassageVi: 'Tôi là học sinh.',
);

const _freeScenario = Scenario(
  id: 'free',
  emoji: '💬',
  jpLabel: '自由会話',
  viLabel: 'Tự do',
  aiPersona: 'Bạn test.',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lượt gửi lỗi (thi Nhật 1)', () {
    test('gỡ bong bóng user + trả câu về draft, điểm không lệch slot',
        () async {
      final ai = FakeAi();
      final c = SpeakingController(
          ai: ai, speech: FakeSpeech(), initialScenario: _examScenario);
      await c.selectScenario(_examScenario);
      expect(c.messages.length, 1); // lời chào của giám khảo

      // Lượt ĐỌC BÀI đầu tiên gặp lỗi mạng.
      ai.failNext = true;
      await c.submitUserText('たなかさんは　がくせいです。');

      // Bong bóng user của lượt lỗi phải bị gỡ (không chiếm slot điểm),
      // câu nói quay về draft để bấm gửi lại, tiến độ thi đứng yên.
      expect(c.messages.length, 1);
      expect(c.examTurnScores, isEmpty);
      expect(c.draft, 'たなかさんは　がくせいです。');
      expect(c.examProgress, 'Đọc bài');
      expect(c.error, isNotNull);

      // Gửi lại thành công → điểm nằm đúng slot [0] (Đọc bài), tiến 1 bước.
      await c.sendDraft();
      expect(c.examTurnScores, [80]);
      expect(c.examProgress, 'Câu 1/4');
      expect(c.messages.length, 3); // chào + user + phản hồi giám khảo
      c.dispose();
    });
  });

  group('Thi Nhật 2 (JPD123)', () {
    test('4 lượt: đọc bài → câu 1 (tranh) → câu 2, 3 → hoàn thành', () async {
      final c = SpeakingController(
          ai: FakeAi(), speech: FakeSpeech(), initialScenario: _nihon2Scenario);
      await c.selectScenario(_nihon2Scenario);
      expect(c.examPhase, 'reading');
      expect(c.examProgress, 'Đọc bài');

      await c.submitUserText('わたしは　がくせいです。'); // đọc bài
      expect(c.examPhase, 'picture'); // câu ① theo tranh
      expect(c.examProgress, 'Câu 1/3');

      await c.submitUserText('２じかんはんです。'); // trả lời câu ①
      expect(c.examPhase, 'free');
      expect(c.examProgress, 'Câu 2/3');

      await c.submitUserText('おかねが　ほしいです。'); // câu ②
      expect(c.examProgress, 'Câu 3/3');
      expect(c.examFinished, false);

      await c.submitUserText('はるが　すきです。'); // câu ③ — hết bài thi
      expect(c.examPhase, 'done');
      expect(c.examProgress, 'Hoàn thành');
      expect(c.examFinished, true);
      // 4 lượt chấm: [0]=đọc bài, [1..3]=3 câu hỏi.
      expect(c.examTurnScores.length, 4);
      c.dispose();
    });
  });

  group('Kết thúc buổi luyện (Tự do)', () {
    test('thành công → có bản phân tích, khóa phiên', () async {
      final c = SpeakingController(
          ai: FakeAi(), speech: FakeSpeech(), initialScenario: _freeScenario);
      await c.selectScenario(_freeScenario);
      await c.submitUserText('こんにちは。');

      await c.endSession();

      expect(c.sessionEnded, true);
      expect(c.analysis, isNotNull);
      expect(c.analysis!.overallScore, 75);
      expect(c.analysis!.sentenceNotes, isNotEmpty);
      c.dispose();
    });

    test('gặp lỗi → không khóa phiên, không có phân tích', () async {
      final ai = FakeAi();
      final c = SpeakingController(
          ai: ai, speech: FakeSpeech(), initialScenario: _freeScenario);
      await c.selectScenario(_freeScenario);
      await c.submitUserText('こんにちは。'); // để hasUserTurn = true

      ai.failNext = true;
      await c.endSession();

      expect(c.sessionEnded, false);
      expect(c.analysis, isNull);
      expect(c.messages.any((m) => m.japanese.contains('🏁')), false);
      expect(c.error, isNotNull);
      c.dispose();
    });
  });

  group('Hội thoại thuần giọng nói (voiceOnly)', () {
    test('Tự do: dừng mic là gửi luôn, không qua draft', () async {
      final speech = FakeSpeech();
      final c = SpeakingController(
          ai: FakeAi(), speech: speech, initialScenario: _freeScenario);
      await c.selectScenario(_freeScenario);
      expect(c.voiceOnly, true);

      await c.toggleMic(); // mở mic
      speech.emitResult('こんにちは。'); // STT chốt một câu
      await c.toggleMic(); // dừng → tự gửi, không có draft

      expect(c.draft, isNull);
      // chào AI + câu user + phản hồi AI = 3 tin nhắn
      expect(c.messages.length, 3);
      expect(c.messages[1].fromUser, true);
      expect(c.messages[1].japanese, 'こんにちは。');
      c.dispose();
    });

    test('chế độ thi vẫn giữ draft xem lại trước khi gửi', () async {
      final speech = FakeSpeech();
      final c = SpeakingController(
          ai: FakeAi(), speech: speech, initialScenario: _examScenario);
      await c.selectScenario(_examScenario);
      expect(c.voiceOnly, false);

      await c.toggleMic();
      speech.emitResult('たなかさんは　がくせいです。');
      await c.toggleMic(); // dừng → vào draft, CHƯA gửi

      expect(c.draft, 'たなかさんは　がくせいです。');
      expect(c.messages.length, 1); // mới chỉ có lời chào giám khảo
      c.dispose();
    });
  });

  group('Chốt mic (finishing)', () {
    test('khóa nút mic trong lúc đợi kết quả STT trễ', () async {
      final c = SpeakingController(
          ai: FakeAi(), speech: FakeSpeech(), initialScenario: _freeScenario);
      await c.selectScenario(_freeScenario);

      await c.toggleMic(); // mở mic
      expect(c.listening, true);

      final stopping = c.toggleMic(); // bấm dừng — bắt đầu chốt câu
      expect(c.finishing, true);
      expect(c.listening, false);

      await c.toggleMic(); // bấm mic trong cửa sổ chốt → phải bị bỏ qua
      expect(c.listening, false);

      await stopping;
      expect(c.finishing, false);
      c.dispose();
    });
  });
}

// AI + Speech giả dùng chung cho các test của feature Speaking.

import 'package:nihon/features/speaking/models/scenario.dart';
import 'package:nihon/features/speaking/services/ai_conversation_service.dart';
import 'package:nihon/features/speaking/services/speech_service.dart';

class FakeAi extends AiConversationService {
  bool failNext = false;

  /// Điểm chấm cho mỗi lượt trả lời (mặc định 80).
  int score = 80;

  @override
  Future<AiTurn> startScenario(Scenario scenario) async => const AiTurn(
        replyJp: 'はじめましょう。',
        replyReading: 'はじめましょう。',
        replyTranslation: 'Bắt đầu nhé.',
      );

  @override
  Future<AiTurn> sendUserUtterance(String text,
      {int? readingMatchPercent}) async {
    if (failNext) {
      failNext = false;
      throw AiServiceException('Gemini đang quá tải.');
    }
    return AiTurn(
      replyJp: 'はい、けっこうです。',
      replyReading: 'はい、けっこうです。',
      replyTranslation: 'Được rồi.',
      pronunciationScore: score,
      feedback: 'Tốt.',
    );
  }
}

class FakeSpeech extends SpeechService {
  @override
  Future<bool> init() async => true;

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => false;

  @override
  bool get jaVoiceAvailable => true;

  @override
  Future<void> startListening({
    required void Function(String text) onResult,
    void Function(String text)? onPartial,
  }) async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> speak(String japanese) async {}

  @override
  void dispose() {}
}

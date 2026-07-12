import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SpeechAssessmentResult {
  final int score;
  final bool isMatch;
  final String feedback;
  final String transcript;

  SpeechAssessmentResult({
    required this.score,
    required this.isMatch,
    required this.feedback,
    required this.transcript,
  });
}

class SpeechAssessmentService {
  static final SpeechAssessmentService _instance = SpeechAssessmentService._internal();
  factory SpeechAssessmentService() => _instance;
  SpeechAssessmentService._internal();

  // API Key có thể được lưu trữ động hoặc cấu hình bởi người dùng
  static const String _apiKeyPrefsKey = 'gemini_api_key';

  String? _geminiApiKey;
  bool _loaded = false;

  Future<void> loadSavedApiKey() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_apiKeyPrefsKey)?.trim();
    _geminiApiKey = savedKey == null || savedKey.isEmpty ? null : savedKey;
    _loaded = true;
  }

  Future<void> setApiKey(String? key) async {
    final normalizedKey = key?.trim();
    _geminiApiKey = normalizedKey == null || normalizedKey.isEmpty
        ? null
        : normalizedKey;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();
    if (_geminiApiKey == null) {
      await prefs.remove(_apiKeyPrefsKey);
    } else {
      await prefs.setString(_apiKeyPrefsKey, _geminiApiKey!);
    }
  }

  String? get apiKey => _geminiApiKey;

  /// Thực hiện đánh giá phát âm: dùng Gemini API nếu có key, ngược lại dùng giải thuật khớp chuỗi cục bộ
  Future<SpeechAssessmentResult> assessSpeech({
    required String target,
    required String transcript,
    String furigana = '',
    String romaji = '',
  }) async {
    final cleanTranscript = _normalize(transcript);
    final cleanTarget = _normalize(target);
    final cleanFurigana = _normalize(furigana);
    final cleanRomaji = _normalize(romaji);

    // Nếu rỗng
    if (cleanTranscript.isEmpty) {
      return SpeechAssessmentResult(
        score: 0,
        isMatch: false,
        feedback: 'Không nghe thấy giọng nói của bạn. Vui lòng thử lại!',
        transcript: '',
      );
    }

    // Nếu có cài đặt API key của Gemini -> sử dụng AI nâng cao
    if (_geminiApiKey != null && _geminiApiKey!.trim().isNotEmpty) {
      try {
        return await _assessWithGemini(
          target: target,
          transcript: transcript,
          furigana: furigana,
          romaji: romaji,
        );
      } catch (e) {
        print("⚠️ Gemini Speech Assessment failed, falling back to local: $e");
      }
    }

    // Thuật toán so khớp cục bộ (Fuzzy Local matching)
    // 1. Kiểm tra khớp chính xác hoặc chứa
    bool exact = cleanTranscript == cleanTarget ||
        cleanTranscript == cleanFurigana ||
        cleanTranscript == cleanRomaji ||
        cleanTarget.contains(cleanTranscript) ||
        cleanTranscript.contains(cleanTarget);

    if (exact) {
      return SpeechAssessmentResult(
        score: 100,
        isMatch: true,
        feedback: 'Tuyệt vời! Bạn phát âm hoàn toàn chính xác. 🎉',
        transcript: transcript,
      );
    }

    // 2. Tính khoảng cách Levenshtein để đo độ tương đồng
    double scoreWord = _calculateSimilarity(cleanTranscript, cleanTarget);
    double scoreFurigana = cleanFurigana.isNotEmpty ? _calculateSimilarity(cleanTranscript, cleanFurigana) : 0.0;
    double scoreRomaji = cleanRomaji.isNotEmpty ? _calculateSimilarity(cleanTranscript, cleanRomaji) : 0.0;

    double bestScore = math.max(scoreWord, math.max(scoreFurigana, scoreRomaji));
    int finalScore = (bestScore * 100).round();

    String feedback = '';
    bool isMatch = finalScore >= 65;

    if (finalScore >= 80) {
      feedback = 'Rất tốt! Phát âm của bạn gần như chính xác. 👍';
    } else if (finalScore >= 60) {
      feedback = 'Khá tốt! Bạn phát âm tương đối giống, hãy nghe lại câu mẫu để hoàn thiện hơn. 💪';
    } else if (finalScore >= 35) {
      feedback = 'Chưa chính xác lắm. Bạn nên nhấn nút phát âm để nghe lại và nói rõ hơn. 🔄';
    } else {
      feedback = 'Phát âm chưa đúng. Hãy thử nói lại một lần nữa thật chậm rãi và rõ ràng nhé!';
    }

    return SpeechAssessmentResult(
      score: finalScore,
      isMatch: isMatch,
      feedback: feedback,
      transcript: transcript,
    );
  }

  /// So sánh độ tương đồng Levenshtein
  double _calculateSimilarity(String s, String t) {
    if (s.isEmpty || t.isEmpty) return 0.0;
    if (s == t) return 1.0;

    int distance = _levenshteinDistance(s, t);
    int maxLength = math.max(s.length, t.length);
    return 1.0 - (distance / maxLength);
  }

  /// Thuật toán Levenshtein Distance
  int _levenshteinDistance(String s, String t) {
    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = math.min(
          v1[j] + 1,
          math.min(
            v0[j + 1] + 1,
            v0[j] + cost,
          ),
        );
      }
      v0 = List<int>.from(v1);
    }
    return v0[t.length];
  }

  /// Chuẩn hóa chuỗi (Xóa dấu câu, viết thường, chuyển katakana -> hiragana)
  String _normalize(String input) {
    String clean = input
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\.,\?!、。？\！\-\_\(\)]'), '');
    return _katakanaToHiragana(clean);
  }

  /// Chuyển Katakana thành Hiragana để so sánh âm
  String _katakanaToHiragana(String input) {
    return String.fromCharCodes(input.codeUnits.map((char) {
      // Katakana Unicode block: 0x30A1 to 0x30F6
      // Hiragana Unicode block starts 0x60 code points lower
      if (char >= 0x30A1 && char <= 0x30F6) {
        return char - 0x60;
      }
      return char;
    }));
  }

  /// Đánh giá phát âm nâng cao qua Gemini API
  Future<SpeechAssessmentResult> _assessWithGemini({
    required String target,
    required String transcript,
    required String furigana,
    required String romaji,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey',
    );

    final prompt = '''
Bạn là một chuyên gia huấn luyện phát âm tiếng Nhật.
Người dùng đang phát âm câu/từ tiếng Nhật sau:
- Từ mục tiêu: "$target"
- Cách đọc Furigana: "$furigana"
- Phiên âm Romaji: "$romaji"

Kết quả nhận diện giọng nói (Speech-to-Text) thu được từ mic của người dùng: "$transcript"

Nhiệm vụ của bạn:
1. Đánh giá xem âm thanh của kết quả nhận diện giọng nói có khớp với từ mục tiêu hay không. Hãy tính đến việc Speech-to-Text đôi khi chuyển chữ Kana thành chữ Hán tự (Kanji) tương đương (ví dụ người dùng đọc "mizu" ghi nhận "みず" hay "水" đều đúng 100%).
2. Cho điểm số từ 0 đến 100 về mức độ chính xác của phát âm.
3. Viết một lời nhận xét ngắn gọn, thân thiện bằng Tiếng Việt (tối đa 2 câu) chỉ ra lỗi phát âm của họ (nếu có) và hướng dẫn cải thiện.

Trả về định dạng JSON thuần túy (không chứa markdown, không nằm trong ```json):
{
  "score": (số nguyên từ 0 đến 100),
  "isMatch": (boolean, true nếu score >= 70),
  "feedback": (chuỗi văn bản tiếng Việt)
}
''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
        }
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final String textContent = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      final Map<String, dynamic> resultJson = jsonDecode(textContent.trim());

      return SpeechAssessmentResult(
        score: resultJson['score'] ?? 50,
        isMatch: resultJson['isMatch'] ?? false,
        feedback: resultJson['feedback'] ?? 'Không thể phân tích phản hồi.',
        transcript: transcript,
      );
    } else {
      throw Exception('Gemini API returned status code ${response.statusCode}');
    }
  }
}

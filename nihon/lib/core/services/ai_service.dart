import 'dart:convert';
import 'package:http/http.dart' as http;
import 'speech_assessment_service.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// Hỏi Trợ lý AI về từ vựng hoặc ngữ pháp
  Future<String> askTutor({required String topic, required String type}) async {
    final apiKey = SpeechAssessmentService().apiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      return 'Vui lòng cấu hình Gemini API Key trước khi sử dụng trợ lý học tập AI!';
    }

    try {
      // Sử dụng model gemini-2.5-flash theo cấu hình của người dùng
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
      );

      final prompt = '''
Bạn là một trợ lý học tiếng Nhật thông minh và nhiệt huyết.
Hãy giải thích chi tiết, ngắn gọn, dễ hiểu về ${type == 'kanji' ? 'chữ Hán tự (Kanji) hoặc Từ vựng' : 'mẫu ngữ pháp'} sau: "$topic".

Yêu cầu nội dung phản hồi:
1. **Giải thích ý nghĩa và sắc thái**: Cách dùng trong đời sống, ngữ cảnh sử dụng (trang trọng hay thân mật, có lưu ý đặc biệt gì không).
2. **Ví dụ thực tế**: Cho đúng 3 câu ví dụ thực tế bằng tiếng Nhật (kèm Furigana phiên âm và dịch nghĩa tiếng Việt).

Hãy trình bày đẹp mắt bằng định dạng Markdown rõ ràng, có tiêu đề và các icon sinh động để tăng tính tương tác.
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
          ]
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final String textContent = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        return textContent.trim();
      } else {
        return 'Yêu cầu gọi Gemini API thất bại với mã trạng thái: ${response.statusCode}';
      }
    } catch (e) {
      return 'Có lỗi xảy ra khi liên hệ Trợ lý AI: $e. Hãy kiểm tra lại API Key hoặc mạng internet!';
    }
  }
}

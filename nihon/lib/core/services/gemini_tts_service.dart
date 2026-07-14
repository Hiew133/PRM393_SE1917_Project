import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// Đọc tiếng Nhật bằng **Gemini TTS** qua Firebase AI Logic — dùng làm
/// fallback trên WEB khi trình duyệt của người dùng không có voice ja-JP
/// (Web Speech API sẽ im lặng dù không báo lỗi).
///
/// Đi chung hạ tầng với AI hội thoại: không API key trong app, App Check
/// bảo vệ sẵn. Audio trả về là PCM 16-bit → gói thành WAV để phát bằng
/// audio element.
class GeminiTtsService {
  GeminiTtsService._();

  static final GeminiTtsService instance = GeminiTtsService._();

  /// Model TTS (Vertex AI). Override khi build:
  /// `--dart-define=GEMINI_TTS_MODEL=gemini-2.5-pro-tts`
  static const String _modelName = String.fromEnvironment(
    'GEMINI_TTS_MODEL',
    defaultValue: 'gemini-2.5-flash-tts',
  );

  /// Giọng đọc prebuilt (Kore đọc ja-JP tự nhiên, giọng nữ).
  static const String _voiceName = 'Kore';

  GenerativeModel? _model;

  /// Cache câu → WAV để câu lặp lại (nghe lại, chào hỏi…) không tốn thêm
  /// lượt gọi server. Giữ tối đa [_maxCacheEntries] câu gần nhất.
  static const int _maxCacheEntries = 40;
  final Map<String, Uint8List> _cache = {};

  /// Tổng hợp [text] thành file WAV. Trả về `null` nếu lỗi (caller giữ
  /// nguyên hành vi im lặng như trước — không chết UI).
  Future<Uint8List?> synthesizeWav(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final cached = _cache[trimmed];
    if (cached != null) return cached;

    try {
      _model ??= FirebaseAI.vertexAI().generativeModel(
        model: _modelName,
        generationConfig: GenerationConfig(
          responseModalities: [ResponseModalities.audio],
          speechConfig: SpeechConfig(
            voiceName: _voiceName,
            languageCode: 'ja-JP',
          ),
        ),
      );
      final res = await _model!.generateContent([Content.text(trimmed)]);

      InlineDataPart? audio;
      for (final candidate in res.candidates) {
        for (final part in candidate.content.parts) {
          if (part is InlineDataPart && part.mimeType.startsWith('audio/')) {
            audio = part;
            break;
          }
        }
        if (audio != null) break;
      }
      if (audio == null) {
        debugPrint('Gemini TTS: response không có audio part.');
        return null;
      }

      final wav = audio.mimeType.contains('wav')
          ? audio.bytes
          : _pcmToWav(audio.bytes, sampleRate: _sampleRateFromMime(audio.mimeType));
      _cachePut(trimmed, wav);
      return wav;
    } catch (e) {
      debugPrint('Gemini TTS failed: $e');
      return null;
    }
  }

  void _cachePut(String key, Uint8List wav) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first); // bỏ entry cũ nhất (insertion order)
    }
    _cache[key] = wav;
  }

  /// Gemini trả PCM dạng `audio/L16;codec=pcm;rate=24000` — đọc rate từ mime.
  int _sampleRateFromMime(String mimeType) {
    final match = RegExp(r'rate=(\d+)').firstMatch(mimeType);
    return int.tryParse(match?.group(1) ?? '') ?? 24000;
  }

  /// Gói PCM 16-bit mono thành WAV (header RIFF 44 byte chuẩn).
  Uint8List _pcmToWav(Uint8List pcm, {required int sampleRate}) {
    const channels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;

    final b = BytesBuilder();
    void ascii(String s) => b.add(s.codeUnits);
    void u32(int v) =>
        b.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
    void u16(int v) => b.add([v & 0xFF, (v >> 8) & 0xFF]);

    ascii('RIFF');
    u32(36 + pcm.length);
    ascii('WAVE');
    ascii('fmt ');
    u32(16); // kích thước chunk fmt
    u16(1); // PCM không nén
    u16(channels);
    u32(sampleRate);
    u32(byteRate);
    u16(blockAlign);
    u16(bitsPerSample);
    ascii('data');
    u32(pcm.length);
    b.add(pcm);
    return b.toBytes();
  }
}

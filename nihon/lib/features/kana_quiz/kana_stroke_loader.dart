import 'package:flutter/services.dart' show rootBundle;

import '../lessons/kanji_data.dart';
import '../lessons/kanji_svg_parser.dart';

/// Tải nét chữ kana từ SVG KanjiVG BUNDLE trong assets (offline).
/// File đặt theo codepoint hex 5 ký tự: あ (U+3042) → `assets/kana_svg/03042.svg`.
class KanaStrokeLoader {
  KanaStrokeLoader._();

  static final Map<String, List<KanjiStroke>> _cache = {};

  /// Danh sách nét (đúng thứ tự viết) của một chữ kana; [] nếu không có file.
  static Future<List<KanjiStroke>> load(String char) async {
    final cached = _cache[char];
    if (cached != null) return cached;
    if (char.isEmpty) return const [];

    try {
      final hex = char.runes.first.toRadixString(16).padLeft(5, '0');
      final svg = await rootBundle.loadString('assets/kana_svg/$hex.svg');
      // Thứ tự thẻ <path> trong KanjiVG chính là thứ tự nét viết.
      final pathRegex = RegExp(r'<path[^>]*\bd="([^"]+)"');
      final strokes = <KanjiStroke>[];
      for (final match in pathRegex.allMatches(svg)) {
        final d = match.group(1);
        if (d == null) continue;
        final points = KanjiSvgParser.parsePathData(d);
        if (points.isNotEmpty) {
          strokes.add(KanjiStroke(points: points, svgPathData: d));
        }
      }
      _cache[char] = strokes;
      return strokes;
    } catch (_) {
      return const [];
    }
  }
}

/// Chấm độ khớp phần READING (thi Nhật 1): so văn bản STT với bài đọc gốc.
///
/// Trả về phần trăm khớp 0–100 dựa trên khoảng cách Levenshtein sau khi đã
/// chuẩn hóa (bỏ khoảng trắng/dấu câu, đổi số full-width về half-width).
/// Lưu ý: STT có thể ghi kanji/kana khác bản gốc (たなか vs 田中) nên con số
/// này là NEO tham khảo đưa cho AI chấm, không dùng thẳng làm điểm cuối.
int readingMatchPercent(String spoken, String passage) {
  final a = _normalize(spoken);
  final b = _normalize(passage);
  if (a.isEmpty || b.isEmpty) return 0;
  final dist = _levenshtein(a, b);
  final maxLen = a.length > b.length ? a.length : b.length;
  return (((maxLen - dist) / maxLen) * 100).round().clamp(0, 100);
}

/// Bỏ khoảng trắng + dấu câu Nhật/Latin, đổi số full-width（０-９）về 0-9.
String _normalize(String s) {
  final buf = StringBuffer();
  for (var c in s.runes) {
    if (c >= 0xFF10 && c <= 0xFF19) c = c - 0xFF10 + 0x30; // ０-９ → 0-9
    final ch = String.fromCharCode(c);
    if (_ignored.contains(ch)) continue;
    buf.write(ch);
  }
  return buf.toString();
}

const Set<String> _ignored = {
  ' ', '　', '\n', '\t',
  '、', '。', '，', '．', '・', '「', '」', '『', '』',
  '！', '？', '～', '〜', '!', '?', ',', '.', ':', '：',
};

int _levenshtein(String a, String b) {
  final m = a.length, n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;
  var prev = List<int>.generate(n + 1, (j) => j);
  var curr = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var best = curr[j - 1] + 1; // chèn
      if (prev[j] + 1 < best) best = prev[j] + 1; // xóa
      if (prev[j - 1] + cost < best) best = prev[j - 1] + cost; // thay
      curr[j] = best;
    }
    final t = prev;
    prev = curr;
    curr = t;
  }
  return prev[n];
}

/// Dữ liệu bảng chữ cái kana (Hiragana + Katakana) cho quiz gõ romaji.
///
/// Chỉ gồm 46 âm CHÍNH (gojūon) mỗi bảng — không dakuten/yōon. Viết cứng để
/// mở là chơi ngay, offline.
class Kana {
  final String char;
  final String romaji; // cách viết romaji để hiển thị

  /// Các cách gõ được CHẤP NHẬN (đã viết thường). Vd し nhận cả "shi" và "si".
  final List<String> accepts;

  const Kana(this.char, this.romaji, [List<String>? accepts])
      : accepts = accepts ?? const [];

  /// Kiểm tra [input] có đúng không (đã chuẩn hóa thường + bỏ khoảng trắng).
  bool matches(String input) {
    final s = input.trim().toLowerCase();
    if (s.isEmpty) return false;
    if (s == romaji.toLowerCase()) return true;
    return accepts.contains(s);
  }
}

/// Một hàng trong bảng gojūon (vd hàng "か": か き く け こ).
class KanaRow {
  final String label; // nhãn hàng (romaji chữ đầu), vd "ka"
  final List<Kana> kana;
  const KanaRow(this.label, this.kana);
}

const List<KanaRow> kHiraganaRows = [
  KanaRow('a', [Kana('あ', 'a'), Kana('い', 'i'), Kana('う', 'u'), Kana('え', 'e'), Kana('お', 'o')]),
  KanaRow('ka', [Kana('か', 'ka'), Kana('き', 'ki'), Kana('く', 'ku'), Kana('け', 'ke'), Kana('こ', 'ko')]),
  KanaRow('sa', [Kana('さ', 'sa'), Kana('し', 'shi', ['si']), Kana('す', 'su'), Kana('せ', 'se'), Kana('そ', 'so')]),
  KanaRow('ta', [Kana('た', 'ta'), Kana('ち', 'chi', ['ti']), Kana('つ', 'tsu', ['tu']), Kana('て', 'te'), Kana('と', 'to')]),
  KanaRow('na', [Kana('な', 'na'), Kana('に', 'ni'), Kana('ぬ', 'nu'), Kana('ね', 'ne'), Kana('の', 'no')]),
  KanaRow('ha', [Kana('は', 'ha'), Kana('ひ', 'hi'), Kana('ふ', 'fu', ['hu']), Kana('へ', 'he'), Kana('ほ', 'ho')]),
  KanaRow('ma', [Kana('ま', 'ma'), Kana('み', 'mi'), Kana('む', 'mu'), Kana('め', 'me'), Kana('も', 'mo')]),
  KanaRow('ya', [Kana('や', 'ya'), Kana('ゆ', 'yu'), Kana('よ', 'yo')]),
  KanaRow('ra', [Kana('ら', 'ra'), Kana('り', 'ri'), Kana('る', 'ru'), Kana('れ', 're'), Kana('ろ', 'ro')]),
  KanaRow('wa', [Kana('わ', 'wa'), Kana('を', 'wo', ['o'])]),
  KanaRow('n', [Kana('ん', 'n', ['nn'])]),
];

const List<KanaRow> kKatakanaRows = [
  KanaRow('a', [Kana('ア', 'a'), Kana('イ', 'i'), Kana('ウ', 'u'), Kana('エ', 'e'), Kana('オ', 'o')]),
  KanaRow('ka', [Kana('カ', 'ka'), Kana('キ', 'ki'), Kana('ク', 'ku'), Kana('ケ', 'ke'), Kana('コ', 'ko')]),
  KanaRow('sa', [Kana('サ', 'sa'), Kana('シ', 'shi', ['si']), Kana('ス', 'su'), Kana('セ', 'se'), Kana('ソ', 'so')]),
  KanaRow('ta', [Kana('タ', 'ta'), Kana('チ', 'chi', ['ti']), Kana('ツ', 'tsu', ['tu']), Kana('テ', 'te'), Kana('ト', 'to')]),
  KanaRow('na', [Kana('ナ', 'na'), Kana('ニ', 'ni'), Kana('ヌ', 'nu'), Kana('ネ', 'ne'), Kana('ノ', 'no')]),
  KanaRow('ha', [Kana('ハ', 'ha'), Kana('ヒ', 'hi'), Kana('フ', 'fu', ['hu']), Kana('ヘ', 'he'), Kana('ホ', 'ho')]),
  KanaRow('ma', [Kana('マ', 'ma'), Kana('ミ', 'mi'), Kana('ム', 'mu'), Kana('メ', 'me'), Kana('モ', 'mo')]),
  KanaRow('ya', [Kana('ヤ', 'ya'), Kana('ユ', 'yu'), Kana('ヨ', 'yo')]),
  KanaRow('ra', [Kana('ラ', 'ra'), Kana('リ', 'ri'), Kana('ル', 'ru'), Kana('レ', 're'), Kana('ロ', 'ro')]),
  KanaRow('wa', [Kana('ワ', 'wa'), Kana('ヲ', 'wo', ['o'])]),
  KanaRow('n', [Kana('ン', 'n', ['nn'])]),
];

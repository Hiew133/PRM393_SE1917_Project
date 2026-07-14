/// Một câu hỏi trắc nghiệm cho trò chơi "Thủ môn bắt bóng".
///
/// Câu hỏi được VIẾT CỨNG (không tải Firestore) để mở trò chơi tức thì,
/// không lag. Bộ hiện tại ôn CÁCH ĐỌC / CÁCH VIẾT Hiragana.
class FootballQuestion {
  /// Nội dung chính được hỏi (từ tiếng Nhật hoặc romaji trong ngoặc).
  final String sentence;

  /// Câu hỏi / gợi ý bằng tiếng Việt.
  final String hintVi;

  /// 4 đáp án.
  final List<String> options;

  /// Vị trí đáp án đúng trong [options].
  final int correctIndex;

  /// Giải thích ngắn khi trả lời xong.
  final String explain;

  const FootballQuestion({
    required this.sentence,
    required this.hintVi,
    required this.options,
    required this.correctIndex,
    required this.explain,
  });

  String get correctAnswer => options[correctIndex];
}

/// Ngân hàng câu hỏi (viết cứng). Mỗi ván bốc ngẫu nhiên N câu.
const List<FootballQuestion> kFootballQuestions = [
  // ── Nhóm 1: Từ vựng đặc biệt ─────────────────────────────
  FootballQuestion(
    sentence: '「doki doki」',
    hintVi: 'Tiếng tim đập thình thịch — viết bằng Hiragana nào?',
    options: ['ときとき', 'どきどき', 'どきとき', 'ときどき'],
    correctIndex: 1,
    explain: 'ど (do) + き (ki) lặp lại: どきどき.',
  ),
  FootballQuestion(
    sentence: '「fuwa fuwa」',
    hintVi: 'Bồng bềnh, mềm mại — viết thế nào?',
    options: ['ふわふわ', 'ほわほわ', 'はわはわ', 'ぬわぬわ'],
    correctIndex: 0,
    explain: 'ふ (fu) + わ (wa) lặp lại: ふわふわ.',
  ),
  FootballQuestion(
    sentence: '「kimochi」',
    hintVi: 'Cảm giác, cảm xúc — viết thế nào?',
    options: ['ぎもち', 'さもち', 'きまつ', 'きもち'],
    correctIndex: 3,
    explain: 'き (ki) + も (mo) + ち (chi): きもち.',
  ),
  FootballQuestion(
    sentence: '「yamete」',
    hintVi: 'Dừng lại đi / đừng mà — viết thế nào?',
    options: ['かめて', 'ゆめて', 'やめて', 'やねて'],
    correctIndex: 2,
    explain: 'や (ya) + め (me) + て (te): やめて.',
  ),
  // ── Nhóm 2: Hiragana cơ bản ──────────────────────────────
  FootballQuestion(
    sentence: 'ねこ',
    hintVi: 'Từ này (con mèo) phát âm là gì?',
    options: ['Neko', 'Inu', 'Tori', 'Sakana'],
    correctIndex: 0,
    explain: 'ね (ne) + こ (ko) = Neko (con mèo).',
  ),
  FootballQuestion(
    sentence: 'いぬ',
    hintVi: 'Từ này (con chó) phát âm là gì?',
    options: ['Neko', 'Inu', 'Uma', 'Usagi'],
    correctIndex: 1,
    explain: 'い (i) + ぬ (nu) = Inu (con chó).',
  ),
  FootballQuestion(
    sentence: 'さくら',
    hintVi: 'Hoa anh đào — Romaji là gì?',
    options: ['Sikura', 'Sakura', 'Sukura', 'Kakura'],
    correctIndex: 1,
    explain: 'さ (sa) + く (ku) + ら (ra) = Sakura.',
  ),
  FootballQuestion(
    sentence: 'すし',
    hintVi: 'Món sushi — gồm những chữ nào ghép lại?',
    options: ['Su + Shi', 'So + Shi', 'Nu + Chi', 'Tsu + Ki'],
    correctIndex: 0,
    explain: 'す (su) + し (shi) = Sushi.',
  ),
  FootballQuestion(
    sentence: 'わたし',
    hintVi: 'Tôi — Romaji là gì?',
    options: ['Watashi', 'Atashi', 'Anata', 'Tomodachi'],
    correctIndex: 0,
    explain: 'わ (wa) + た (ta) + し (shi) = Watashi.',
  ),
  FootballQuestion(
    sentence: 'あさ',
    hintVi: 'Buổi sáng — đọc là gì?',
    options: ['Aka', 'Ame', 'Asa', 'Soko'],
    correctIndex: 2,
    explain: 'あ (a) + さ (sa) = Asa.',
  ),
  // ── Nhóm 3: Giao tiếp & biến âm ──────────────────────────
  FootballQuestion(
    sentence: 'おはよう',
    hintVi: 'Chào buổi sáng — Romaji chính xác?',
    options: ['Ohayou', 'Ohiyou', 'Oheyou', 'Okayou'],
    correctIndex: 0,
    explain: 'お-は-よ-う = Ohayou.',
  ),
  FootballQuestion(
    sentence: 'ありがとう',
    hintVi: 'Cảm ơn — đọc như thế nào?',
    options: ['Aligato', 'Arigatou', 'Arikatou', 'Arigatoo'],
    correctIndex: 1,
    explain: 'あ-り-が-と-う = Arigatou (が là biến âm).',
  ),
  FootballQuestion(
    sentence: 'かぞく',
    hintVi: 'Gia đình (có tenten) — đọc là gì?',
    options: ['Kasoku', 'Kazoku', 'Katoku', 'Kanoku'],
    correctIndex: 1,
    explain: 'ぞ = そ + tenten = zo → Kazoku.',
  ),
  FootballQuestion(
    sentence: 'ふじさん',
    hintVi: 'Núi Phú Sĩ — Romaji là gì?',
    options: ['Fujisan', 'Hujihan', 'Fujichan', 'Huzisan'],
    correctIndex: 0,
    explain: 'ふ-じ-さ-ん = Fujisan (じ = ji).',
  ),
  FootballQuestion(
    sentence: 'こんにちは',
    hintVi: 'Chữ cuối 「は」 ở đây phát âm là gì?',
    options: ['Ha', 'Wa', 'Wo', 'Na'],
    correctIndex: 1,
    explain: 'は khi làm trợ từ đọc là "wa": Konnichiwa.',
  ),
];

/// Bộ 5 câu CỐ ĐỊNH dùng khi người chơi chọn "5 câu" (đúng thứ tự này).
const List<FootballQuestion> kFootballFiveSet = [
  FootballQuestion(
    sentence: '"Dừng lại đi"',
    hintVi: 'Trong tiếng Nhật là gì?',
    options: ['Yamada', 'Yare yare', 'Yamete', 'Yayature'],
    correctIndex: 2,
    explain: 'やめて (yamete) = "dừng lại đi / đừng mà".',
  ),
  FootballQuestion(
    sentence: 'どき　どき',
    hintVi: 'Từ này đọc là gì?',
    options: ['Toki toki', 'Hori hori', 'Fori fori', 'Doki doki'],
    correctIndex: 3,
    explain: 'どきどき = doki doki (tim đập thình thịch).',
  ),
  FootballQuestion(
    sentence: '"Cảm giác"',
    hintVi: 'Trong tiếng Nhật là gì?',
    options: ['Kimono', 'Kimochi', 'Kimricha', 'Kimchi'],
    correctIndex: 1,
    explain: '気持ち (kimochi) = cảm giác, cảm xúc.',
  ),
  FootballQuestion(
    sentence: '"Hoa anh đào"',
    hintVi: 'Tiếng Nhật là gì?',
    options: ['Sakutara', 'Sasuke', 'Sahara', 'Sakura'],
    correctIndex: 3,
    explain: '桜 (sakura) = hoa anh đào.',
  ),
  FootballQuestion(
    sentence: 'Gọi "Anh Chaien"',
    hintVi: 'Trong tiếng Nhật gọi thế nào cho thân mật?',
    options: ['Chaien', 'Chaien uni', 'Chaien opso', 'Chaien chan'],
    correctIndex: 3,
    explain: 'Thêm hậu tố ちゃん (chan) — cách gọi thân mật của tiếng Nhật (uni/opso là tiếng Hàn).',
  ),
];

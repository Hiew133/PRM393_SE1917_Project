import 'package:flutter/material.dart';

class KanjiStroke {
  /// Danh sách các điểm normalized (từ 0.0 đến 1.0) định nghĩa nét vẽ đúng.
  final List<Offset> points;
  final String? svgPathData;

  const KanjiStroke({required this.points, this.svgPathData});

  Offset get startPoint => points.first;
  Offset get endPoint => points.last;
}

class KanjiData {
  final String character;
  final String hanViet;
  final String onyomi;
  final String kunyomi;
  final String meaning;
  final List<String> examples;
  final List<KanjiStroke> strokes;

  const KanjiData({
    required this.character,
    required this.hanViet,
    required this.onyomi,
    required this.kunyomi,
    required this.meaning,
    required this.examples,
    required this.strokes,
  });
}

class GrammarExample {
  final String exampleJa;
  final String exampleVi;

  const GrammarExample({
    required this.exampleJa,
    required this.exampleVi,
  });
}

class GrammarPoint {
  final String title;
  final String subTitle;
  final String pattern;
  final String note;
  final List<GrammarExample> examples;

  const GrammarPoint({
    required this.title,
    required this.subTitle,
    required this.pattern,
    required this.note,
    required this.examples,
  });
}

class LessonData {
  final String title;
  final String jpTitle;
  final String description;
  final List<KanjiData> kanjis;

  const LessonData({
    required this.title,
    required this.jpTitle,
    required this.description,
    required this.kanjis,
  });
}

// ── Định nghĩa nét vẽ cho các chữ Hán Demo ──────────────────────────

// Chữ 一 (NHẤT)
const _strokesIchi = [
  KanjiStroke(points: [Offset(0.2, 0.5), Offset(0.8, 0.5)]),
];

// Chữ 二 (NHỊ)
const _strokesNi = [
  KanjiStroke(points: [Offset(0.3, 0.35), Offset(0.7, 0.35)]),
  KanjiStroke(points: [Offset(0.2, 0.65), Offset(0.8, 0.65)]),
];

// Chữ 三 (TAM)
const _strokesSan = [
  KanjiStroke(points: [Offset(0.3, 0.25), Offset(0.7, 0.25)]),
  KanjiStroke(points: [Offset(0.35, 0.5), Offset(0.65, 0.5)]),
  KanjiStroke(points: [Offset(0.2, 0.75), Offset(0.8, 0.75)]),
];

// Chữ 川 (XUYÊN) - 3 nét dọc
const _strokesKawa = [
  KanjiStroke(points: [Offset(0.3, 0.25), Offset(0.3, 0.75)]),
  KanjiStroke(points: [Offset(0.5, 0.3), Offset(0.5, 0.7)]),
  KanjiStroke(points: [Offset(0.7, 0.2), Offset(0.7, 0.8)]),
];

// Chữ 口 (KHẨU)
const _strokesKuchi = [
  KanjiStroke(points: [Offset(0.25, 0.25), Offset(0.25, 0.75)]), // Nét 1: dọc trái
  KanjiStroke(points: [Offset(0.25, 0.25), Offset(0.75, 0.25), Offset(0.75, 0.75)]), // Nét 2: ngang móc xuống
  KanjiStroke(points: [Offset(0.25, 0.75), Offset(0.75, 0.75)]), // Nét 3: đóng đáy
];

// Chữ 日 (NHẬT)
const _strokesNichi = [
  KanjiStroke(points: [Offset(0.3, 0.25), Offset(0.3, 0.75)]), // dọc trái
  KanjiStroke(points: [Offset(0.3, 0.25), Offset(0.7, 0.25), Offset(0.7, 0.75)]), // ngang móc xuống
  KanjiStroke(points: [Offset(0.3, 0.5), Offset(0.7, 0.5)]), // ngang giữa
  KanjiStroke(points: [Offset(0.3, 0.75), Offset(0.7, 0.75)]), // ngang đáy
];

// Chữ 月 (NGUYỆT)
const _strokesGetsu = [
  KanjiStroke(points: [Offset(0.3, 0.25), Offset(0.3, 0.8)]), // dọc trái hơi cong
  KanjiStroke(points: [Offset(0.3, 0.25), Offset(0.7, 0.25), Offset(0.7, 0.8)]), // ngang móc
  KanjiStroke(points: [Offset(0.3, 0.45), Offset(0.7, 0.45)]), // ngang giữa 1
  KanjiStroke(points: [Offset(0.3, 0.6), Offset(0.7, 0.6)]), // ngang giữa 2
];

// Chữ 土 (THỔ)
const _strokesTsuchi = [
  KanjiStroke(points: [Offset(0.3, 0.45), Offset(0.7, 0.45)]), // ngang ngắn
  KanjiStroke(points: [Offset(0.5, 0.2), Offset(0.5, 0.75)]), // dọc
  KanjiStroke(points: [Offset(0.2, 0.75), Offset(0.8, 0.75)]), // ngang dài
];

// Chữ 木 (MỘC)
const _strokesKi = [
  KanjiStroke(points: [Offset(0.2, 0.45), Offset(0.8, 0.45)]), // ngang
  KanjiStroke(points: [Offset(0.5, 0.2), Offset(0.5, 0.8)]), // dọc
  KanjiStroke(points: [Offset(0.5, 0.45), Offset(0.25, 0.75)]), // xiên trái
  KanjiStroke(points: [Offset(0.5, 0.45), Offset(0.75, 0.75)]), // xiên phải
];

// Chữ 火 (HỎA)
const _strokesHi = [
  KanjiStroke(points: [Offset(0.3, 0.4), Offset(0.2, 0.5)]), // chấm trái
  KanjiStroke(points: [Offset(0.7, 0.4), Offset(0.8, 0.5)]), // chấm phải
  KanjiStroke(points: [Offset(0.5, 0.25), Offset(0.35, 0.8)]), // xiên giữa trái
  KanjiStroke(points: [Offset(0.5, 0.35), Offset(0.75, 0.8)]), // xiên phải
];

// Chữ 水 (THỦY)
const _strokesMizu = [
  KanjiStroke(points: [Offset(0.5, 0.2), Offset(0.5, 0.75), Offset(0.45, 0.7)]), // dọc móc trái
  KanjiStroke(points: [Offset(0.35, 0.4), Offset(0.2, 0.5)]), // xiên trái trên
  KanjiStroke(points: [Offset(0.2, 0.65), Offset(0.4, 0.5)]), // xiên trái dưới (hất từ dưới-trái lên trên-phải)
  KanjiStroke(points: [Offset(0.65, 0.35), Offset(0.8, 0.7)]), // xiên phải
];

// Chữ 私 (TƯ) - 7 nét thực tế
const _strokesWatashi = [
  KanjiStroke(points: [Offset(0.32, 0.16), Offset(0.18, 0.26)]), // Nét 1: phẩy trái trên của bộ Hòa
  KanjiStroke(points: [Offset(0.12, 0.4), Offset(0.48, 0.4)]),   // Nét 2: ngang bộ Hòa
  KanjiStroke(points: [Offset(0.3, 0.26), Offset(0.3, 0.85)]),   // Nét 3: sổ thẳng dọc bộ Hòa
  KanjiStroke(points: [Offset(0.3, 0.4), Offset(0.14, 0.75)]),   // Nét 4: phẩy trái bộ Hòa
  KanjiStroke(points: [Offset(0.3, 0.4), Offset(0.48, 0.72)]),   // Nét 5: chấm phải bộ Hòa
  KanjiStroke(points: [Offset(0.68, 0.35), Offset(0.56, 0.56), Offset(0.82, 0.56)]), // Nét 6: phẩy gập của bộ Tư (ム)
  KanjiStroke(points: [Offset(0.66, 0.54), Offset(0.76, 0.72)]), // Nét 7: chấm phải của bộ Tư (ム)
];

// Chữ 人 (NHÂN) - 2 nét thực tế
const _strokesHito = [
  KanjiStroke(points: [Offset(0.5, 0.2), Offset(0.4, 0.4), Offset(0.2, 0.8)]), // Nét 1: phẩy trái
  KanjiStroke(points: [Offset(0.42, 0.45), Offset(0.8, 0.8)]), // Nét 2: mác phải
];

// Chữ 才 (TÀI) - 3 nét thực tế
const _strokesSai = [
  KanjiStroke(points: [Offset(0.2, 0.41), Offset(0.8, 0.37)]), // Nét 1: ngang (hơi xếch lên phải)
  KanjiStroke(points: [Offset(0.5, 0.15), Offset(0.5, 0.8), Offset(0.38, 0.72)]), // Nét 2: sổ móc
  KanjiStroke(points: [Offset(0.64, 0.44), Offset(0.24, 0.76)]), // Nét 3: phẩy xiên trái (bắt đầu bên phải sổ thẳng, vẽ chéo qua trái)
];

// Chữ 生 (SINH) - 5 nét thực tế
const _strokesSei = [
  KanjiStroke(points: [Offset(0.46, 0.15), Offset(0.32, 0.28)]), // Nét 1: phẩy trái trên
  KanjiStroke(points: [Offset(0.32, 0.28), Offset(0.72, 0.28)]), // Nét 2: ngang trên ngắn
  KanjiStroke(points: [Offset(0.5, 0.28), Offset(0.5, 0.8)]),   // Nét 3: sổ thẳng dọc
  KanjiStroke(points: [Offset(0.34, 0.52), Offset(0.66, 0.52)]), // Nét 4: ngang giữa
  KanjiStroke(points: [Offset(0.2, 0.8), Offset(0.8, 0.8)]),     // Nét 5: ngang đáy dài
];

// Chữ 本 (BẢN) - 5 nét thực tế
const _strokesHon = [
  KanjiStroke(points: [Offset(0.2, 0.38), Offset(0.8, 0.38)]), // Nét 1: ngang bộ Mộc
  KanjiStroke(points: [Offset(0.5, 0.15), Offset(0.5, 0.85)]), // Nét 2: sổ thẳng dọc bộ Mộc
  KanjiStroke(points: [Offset(0.5, 0.38), Offset(0.22, 0.72)]), // Nét 3: phẩy trái bộ Mộc
  KanjiStroke(points: [Offset(0.5, 0.38), Offset(0.78, 0.72)]), // Nét 4: mác phải bộ Mộc
  KanjiStroke(points: [Offset(0.32, 0.66), Offset(0.68, 0.66)]), // Nét 5: nét ngang ngắn chỉ gốc rễ ở chân
];

// Chữ 学 (HỌC) - 8 nét thực tế
const _strokesGaku = [
  KanjiStroke(points: [Offset(0.34, 0.14), Offset(0.36, 0.26)]), // Nét 1: chấm trái
  KanjiStroke(points: [Offset(0.5, 0.12), Offset(0.5, 0.24)]),   // Nét 2: chấm giữa
  KanjiStroke(points: [Offset(0.66, 0.14), Offset(0.64, 0.26)]), // Nét 3: chấm phải
  KanjiStroke(points: [Offset(0.24, 0.34), Offset(0.24, 0.44)]), // Nét 4: phẩy dọc bên trái
  KanjiStroke(points: [Offset(0.24, 0.34), Offset(0.76, 0.34), Offset(0.76, 0.44)]), // Nét 5: ngang gập móc bên phải của bộ Mịch (冖)
  KanjiStroke(points: [Offset(0.38, 0.52), Offset(0.62, 0.52), Offset(0.38, 0.66)]), // Nét 6: ngang gập của chữ Tử (子)
  KanjiStroke(points: [Offset(0.5, 0.52), Offset(0.5, 0.88), Offset(0.4, 0.84)]), // Nét 7: sổ cong móc của chữ Tử (子)
  KanjiStroke(points: [Offset(0.26, 0.66), Offset(0.74, 0.66)]), // Nét 8: ngang dài cắt ngang chữ Tử (子)
];

// Chữ 十 (THẬP) - 2 nét thực tế
const _strokesJuu = [
  KanjiStroke(points: [Offset(0.2, 0.5), Offset(0.8, 0.5)]), // Nét 1: ngang
  KanjiStroke(points: [Offset(0.5, 0.2), Offset(0.5, 0.8)]), // Nét 2: sổ dọc
];

// Chữ 円 (YÊN) - 4 nét thực tế
const _strokesEn = [
  KanjiStroke(points: [Offset(0.26, 0.25), Offset(0.26, 0.85)]), // Nét 1: sổ trái
  KanjiStroke(points: [Offset(0.26, 0.25), Offset(0.74, 0.25), Offset(0.74, 0.85), Offset(0.66, 0.8)]), // Nét 2: ngang gập móc xuống
  KanjiStroke(points: [Offset(0.5, 0.25), Offset(0.5, 0.8)]),    // Nét 3: sổ giữa (vẽ trước nét ngang đóng đáy)
  KanjiStroke(points: [Offset(0.26, 0.55), Offset(0.74, 0.55)]), // Nét 4: ngang giữa
];

// Chữ 金 (KIM) - 8 nét thực tế
const _strokesKane = [
  KanjiStroke(points: [Offset(0.5, 0.15), Offset(0.22, 0.42)]), // Nét 1: phẩy trái trên mái nhà
  KanjiStroke(points: [Offset(0.5, 0.15), Offset(0.78, 0.42)]), // Nét 2: mác phải trên mái nhà
  KanjiStroke(points: [Offset(0.36, 0.46), Offset(0.64, 0.46)]), // Nét 3: ngang ngắn trên
  KanjiStroke(points: [Offset(0.28, 0.62), Offset(0.72, 0.62)]), // Nét 4: ngang dài giữa
  KanjiStroke(points: [Offset(0.5, 0.46), Offset(0.5, 0.86)]),   // Nét 5: sổ thẳng đứng dọc giữa
  KanjiStroke(points: [Offset(0.42, 0.72), Offset(0.34, 0.76)]), // Nét 6: phẩy chấm bên trái
  KanjiStroke(points: [Offset(0.58, 0.72), Offset(0.66, 0.76)]), // Nét 7: phẩy chấm bên phải
  KanjiStroke(points: [Offset(0.2, 0.86), Offset(0.8, 0.86)]),   // Nét 8: ngang đáy dài
];

const List<GrammarPoint> kGrammarPoints = [
  GrammarPoint(
    title: 'A は B です',
    subTitle: 'Câu khẳng định với danh từ',
    pattern: 'A は B です',
    note: 'A và B là danh từ hoặc cụm danh từ. Dùng để giới thiệu tên, nghề nghiệp, tuổi, quốc tịch, sở thích hoặc vị trí.',
    examples: [
      GrammarExample(
        exampleJa: 'わたしはゴックアインです。',
        exampleVi: 'Tôi là Ngọc Anh.',
      ),
      GrammarExample(
        exampleJa: 'Sonさんは学生です。',
        exampleVi: 'Bạn Sơn là sinh viên.',
      ),
      GrammarExample(
        exampleJa: 'スーパーはちかてつです。',
        exampleVi: 'Siêu thị ở tầng hầm.',
      ),
    ],
  ),
  GrammarPoint(
    title: 'N1 と N2',
    subTitle: 'Liệt kê danh từ',
    pattern: 'N1 と N2',
    note: 'と dùng giữa các danh từ để liệt kê theo nghĩa "và".',
    examples: [
      GrammarExample(
        exampleJa: 'しゅみはサッカーと読書です。',
        exampleVi: 'Sở thích là bóng đá và đọc sách.',
      ),
    ],
  ),
  GrammarPoint(
    title: 'N1 の N2',
    subTitle: 'Nối hai danh từ',
    pattern: 'N1 の N2',
    note: 'N2 là danh từ chính, N1 bổ nghĩa cho N2. Có thể chỉ sở hữu, xuất xứ, nội dung hoặc sự trực thuộc.',
    examples: [
      GrammarExample(
        exampleJa: '私のなまえはSonです。',
        exampleVi: 'Tên của tôi là Sơn.',
      ),
      GrammarExample(
        exampleJa: 'これは日本語の本です。',
        exampleVi: 'Đây là sách tiếng Nhật.',
      ),
      GrammarExample(
        exampleJa: 'AさんはFPTのしゃいんです。',
        exampleVi: 'Bạn A là nhân viên công ty FPT.',
      ),
    ],
  ),
  GrammarPoint(
    title: 'A は B じゃありません',
    subTitle: 'Câu phủ định với danh từ',
    pattern: 'A は B じゃありません',
    note: 'Dùng để nói A không phải là B. Sau đó có thể thêm câu đúng bằng dạng です.',
    examples: [
      GrammarExample(
        exampleJa: 'これは本じゃありません。ノートです。',
        exampleVi: 'Đây không phải là sách. Là quyển vở.',
      ),
      GrammarExample(
        exampleJa: '私は銀行員じゃありません。',
        exampleVi: 'Tôi không phải là nhân viên ngân hàng.',
      ),
    ],
  ),
  GrammarPoint(
    title: 'A は B ですか',
    subTitle: 'Câu hỏi yes/no',
    pattern: 'A は B ですか',
    note: 'Thêm か vào cuối câu khẳng định để hỏi xác nhận. Trả lời đúng bằng はい, sai bằng いいえ.',
    examples: [
      GrammarExample(
        exampleJa: 'パクさんは学生ですか。はい、学生です。',
        exampleVi: 'Bạn Park có phải là sinh viên không? Vâng, là sinh viên.',
      ),
      GrammarExample(
        exampleJa: 'いいえ、学生です。',
        exampleVi: 'Không, là sinh viên. (trả lời thông tin đúng)',
      ),
      GrammarExample(
        exampleJa: 'いいえ、ちがいます。',
        exampleVi: 'Không, không đúng.',
      ),
    ],
  ),
  GrammarPoint(
    title: 'Từ để hỏi',
    subTitle: 'だれ, なんさい, どこ, なん, いくら, いつ',
    pattern: 'Từ để hỏi + ですか',
    note: 'Dùng từ để hỏi khi muốn biết thông tin cụ thể: người, tuổi, nghề nghiệp, quốc gia, tên, địa điểm, giá tiền hoặc thời gian.',
    examples: [
      GrammarExample(
        exampleJa: 'そちらはだれですか。',
        exampleVi: 'Đó là ai vậy?',
      ),
      GrammarExample(
        exampleJa: 'カルロスさんはなんさいですか。',
        exampleVi: 'Bạn Carlos bao nhiêu tuổi?',
      ),
      GrammarExample(
        exampleJa: 'これはいくらですか。',
        exampleVi: 'Cái này bao nhiêu tiền?',
      ),
    ],
  ),
];

// ── DANH SÁCH BÀI HỌC THỰC TẾ (Từ file PDF của bạn) ─────────────────
final List<LessonData> kLessonsList = [
  LessonData(
    title: 'Hán tự bài 1: Giới thiệu bản thân',
    jpTitle: '漢字 第1課：自己紹介',
    description: 'Học các chữ Hán cơ bản thường gặp khi giới thiệu bản thân: 私, 人, 才, 学, 生, 校, 日, 本, 語.',
    kanjis: [
      KanjiData(
        character: '私',
        hanViet: 'TƯ',
        onyomi: 'し',
        kunyomi: 'わたし',
        meaning: 'Tôi (bản thân)',
        examples: [
          '私 (わたし): Tôi',
          '私立 (しりつ): Tư lập, tư nhân',
        ],
        strokes: _strokesWatashi,
      ),
      KanjiData(
        character: '人',
        hanViet: 'NHÂN',
        onyomi: 'じん・にん',
        kunyomi: 'ひと',
        meaning: 'Người, con người',
        examples: [
          '人 (ひと): Người',
          '日本人 (にほんじん): Người Nhật',
          '3人 (さんにん): 3 người',
        ],
        strokes: _strokesHito,
      ),
      KanjiData(
        character: '才',
        hanViet: 'TÀI',
        onyomi: 'さい',
        kunyomi: 'Không có',
        meaning: 'Tuổi (đếm tuổi)',
        examples: [
          '4才 (よんさい): 4 tuổi',
          '20才 (はたち): 20 tuổi (đặc biệt)',
        ],
        strokes: _strokesSai,
      ),
      KanjiData(
        character: '学',
        hanViet: 'HỌC',
        onyomi: 'がく',
        kunyomi: 'Không có',
        meaning: 'Học tập, trường lớp',
        examples: [
          '学生 (がくせい): Học sinh, sinh viên',
          '学校 (がっこう): Trường học',
        ],
        strokes: _strokesGaku,
      ),
      KanjiData(
        character: '生',
        hanViet: 'SINH',
        onyomi: 'せい',
        kunyomi: 'Không có',
        meaning: 'Sinh ra, sinh sống',
        examples: [
          '学生 (がくせい): Học sinh',
        ],
        strokes: _strokesSei,
      ),
      KanjiData(
        character: '日',
        hanViet: 'NHẬT',
        onyomi: 'にち・じつ',
        kunyomi: 'ひ・か',
        meaning: 'Ngày, mặt trời, Nhật Bản',
        examples: [
          '日 (ひ): Ngày, mặt trời',
          '4日 (よっか): Ngày mùng 4',
          '20日 (はつか): Ngày 20',
        ],
        strokes: _strokesNichi,
      ),
      KanjiData(
        character: '本',
        hanViet: 'BẢN/BỔN',
        onyomi: 'ほん',
        kunyomi: 'Không có',
        meaning: 'Sách, gốc rễ, Nhật Bản',
        examples: [
          '日本 (にほん): Nhật Bản',
          '日本語 (にほんご): Tiếng Nhật',
        ],
        strokes: _strokesHon,
      ),
    ],
  ),
  LessonData(
    title: 'Hán tự bài 2: Số đếm & Tiền tệ',
    jpTitle: '漢字 第2課：数字と通貨',
    description: 'Học cách đếm số và đơn vị tiền tệ Nhật Bản: 一, 二, 三, 四, 五, 六, 七, 八, 九, 十, 百, 千, 万, 円.',
    kanjis: [
      KanjiData(
        character: '一',
        hanViet: 'NHẤT',
        onyomi: 'いち',
        kunyomi: 'ひと・つ',
        meaning: 'Số một (1)',
        examples: [
          '一 (いち): Số 1',
          '一つ (ひとつ): 1 cái',
          '一日 (ついたち): Ngày mùng 1',
          '一人 (ひとり): 1 người',
        ],
        strokes: _strokesIchi,
      ),
      KanjiData(
        character: '二',
        hanViet: 'NHỊ',
        onyomi: 'に',
        kunyomi: 'ふた・つ',
        meaning: 'Số hai (2)',
        examples: [
          '二 (に): Số 2',
          '二つ (ふたつ): 2 cái',
          '二日 (futsuka): Ngày mùng 2',
          '二人 (ふたり): 2 người',
        ],
        strokes: _strokesNi,
      ),
      KanjiData(
        character: '三',
        hanViet: 'TAM',
        onyomi: 'san',
        kunyomi: 'みっ・つ',
        meaning: 'Số ba (3)',
        examples: [
          '三 (さん): Số 3',
          '三つ (みっつ): 3 cái',
          '三日 (みっか): Ngày mùng 3',
        ],
        strokes: _strokesSan,
      ),
      KanjiData(
        character: '十',
        hanViet: 'THẬP',
        onyomi: 'じゅう',
        kunyomi: 'とお',
        meaning: 'Số mười (10)',
        examples: [
          '十 (じゅう): Số 10',
          '十日 (とおか): Ngày mùng 10',
        ],
        strokes: _strokesJuu,
      ),
      KanjiData(
        character: '円',
        hanViet: 'YÊN',
        onyomi: 'えん',
        kunyomi: 'Không có',
        meaning: 'Tiền Yên Nhật, vòng tròn',
        examples: [
          '円 (えん): Yên Nhật',
          '一万円 (いちまんえん): 1 vạn Yên',
        ],
        strokes: _strokesEn,
      ),
    ],
  ),
  LessonData(
    title: 'Hán tự bài 3: Thời gian & Thứ ngày',
    jpTitle: '漢字 第3課：時間と曜日',
    description: 'Học về các thứ trong tuần và các chữ chỉ thời gian: 月, 火, 水, 木, 金, 土, 曜, 何, 年, 時, 間, 分, 半.',
    kanjis: [
      KanjiData(
        character: '月',
        hanViet: 'NGUYỆT',
        onyomi: 'げつ・がつ',
        kunyomi: 'つき',
        meaning: 'Tháng, mặt trăng, thứ Hai',
        examples: [
          '月 (つき): Mặt trăng',
          '月曜日 (げつようび): Thứ Hai',
          '四月 (しがつ): Tháng Tư',
        ],
        strokes: _strokesGetsu,
      ),
      KanjiData(
        character: '火',
        hanViet: 'HỎA',
        onyomi: 'か',
        kunyomi: 'ひ',
        meaning: 'Lửa, thứ Ba',
        examples: [
          '火 (ひ): Lửa',
          '火曜日 (かようび): Thứ Ba',
          '花火 (はなび): Pháo hoa',
        ],
        strokes: _strokesHi,
      ),
      KanjiData(
        character: '水',
        hanViet: 'THỦY',
        onyomi: 'すい',
        kunyomi: 'みず',
        meaning: 'Nước, thứ Tư',
        examples: [
          '水 (みず): Nước',
          '水曜日 (すいようび): Thứ Tư',
        ],
        strokes: _strokesMizu,
      ),
      KanjiData(
        character: '木',
        hanViet: 'MỘC',
        onyomi: 'もく',
        kunyomi: 'き',
        meaning: 'Cây cối, thứ Năm',
        examples: [
          '木 (き): Cây',
          '木曜日 (もくようび): Thứ Năm',
        ],
        strokes: _strokesKi,
      ),
      KanjiData(
        character: '金',
        hanViet: 'KIM',
        onyomi: 'きん',
        kunyomi: 'kane',
        meaning: 'Tiền, vàng, thứ Sáu',
        examples: [
          'お金 (おかね): Tiền',
          '金曜日 (きんようび): Thứ Sáu',
        ],
        strokes: _strokesKane,
      ),
      KanjiData(
        character: '土',
        hanViet: 'THỔ',
        onyomi: 'ど',
        kunyomi: 'つち',
        meaning: 'Đất đai, thứ Bảy',
        examples: [
          '土 (つち): Đất',
          '土曜日 (どようび): Thứ Bảy',
        ],
        strokes: _strokesTsuchi,
      ),
    ],
  ),
];

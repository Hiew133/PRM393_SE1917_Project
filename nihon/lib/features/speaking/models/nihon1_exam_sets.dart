import 'scenario.dart';

/// Một ĐỀ thi nói Nhật 1 (JPD113) — format theo "Hướng dẫn ôn tập thi nói
/// JPD113" của trường (100đ):
///
/// 1. **READING (30đ):** SV **đọc to** đoạn văn ~100 ký tự — chỉ cần đọc chính
///    xác, KHÔNG có câu hỏi về nội dung. Giám khảo chấm theo chữ.
/// 2. **TALKING (60đ = 4 câu × 15đ):**
///    - 3 câu hỏi **theo tranh** (giám thị chọn 1 tranh, hỏi 3 câu liên quan,
///      SV nhìn gợi ý trên tranh trả lời).
///    - 1 câu hỏi **tự do** (không tranh, chọn từ danh sách mẫu).
/// 3. **PRESENTING (10đ):** tác phong + phát âm.
class Nihon1ExamSet {
  final String id;
  final String title; // nhãn tiếng Việt, vd "Đề 1 · ..."
  final String passage; // bài đọc — SV ĐỌC TO (tiếng Nhật, hiragana N5)
  final String passageVi; // dịch bài đọc
  final ExamPicture picture; // tranh của phần TALKING
  final List<String> pictureQuestions; // đúng 3 câu hỏi theo tranh
  final String freeQuestion; // 1 câu hỏi tự do (không tranh)

  const Nihon1ExamSet({
    required this.id,
    required this.title,
    required this.passage,
    required this.passageVi,
    required this.picture,
    required this.pictureQuestions,
    required this.freeQuestion,
  });
}

/// Ngân hàng đề Nhật 1 (bốc 1 trong số này).
///
/// Tranh soạn theo 3 dạng mẫu trong tài liệu: giới thiệu NGƯỜI (Sample 1),
/// ĐỒ VẬT + giá tiền (Sample 2), ĐỊA ĐIỂM + giờ mở cửa (Sample 3).
const List<Nihon1ExamSet> kNihon1ExamSets = [
  Nihon1ExamSet(
    id: 'n1_1',
    title: 'Đề 1 · Đọc: Lớp tiếng Nhật — Tranh: người (アリさん)',
    passage: 'たなかさんは　日本語の学生です。クラスは　月曜日と水曜日に　あります。'
        'クラスは　9時から12時までです。先生は　たけだ先生です。'
        'たけだ先生は　しんせつです。たなかさんの　ともだちは　スミスさんです。'
        'スミスさんは　アメリカ人です。でも、まいにち　日本語を　べんきょうします。',
    passageVi: 'Anh Tanaka là sinh viên tiếng Nhật. Lớp học vào thứ Hai và thứ Tư. '
        'Lớp học từ 9 giờ đến 12 giờ. Giáo viên là thầy Takeda. '
        'Thầy Takeda tốt bụng. Bạn của Tanaka là Smith. '
        'Smith là người Mỹ. Nhưng ngày nào cũng học tiếng Nhật.',
    picture: ExamPicture(
      emoji: '👨🏽‍💼',
      caption: 'アリさん',
      hints: [
        'なまえ：アリ',
        '２８さい',
        'しごと：ぎんこういん 🏦',
        'くに：マレーシア',
        'しゅみ：テニス 🎾',
      ],
    ),
    pictureQuestions: [
      'この　ひとの　なまえは　なんですか。',
      'アリさんの　おしごとは　なんですか。',
      'アリさんの　しゅみは　なんですか。',
    ],
    freeQuestion: 'まいにち、なにを　しますか。',
  ),
  Nihon1ExamSet(
    id: 'n1_2',
    title: 'Đề 2 · Đọc: Nhân viên công ty — Tranh: đồ vật (とけい)',
    passage: '私は　パクです。かいしゃいんです。月曜日から金曜日まで、7時に　でんしゃで'
        'かいしゃに　いきます。せんしゅう、あたらしい　ともだちが　できました。'
        'ともだちの　なまえは　やまださんです。やまださんは　しんせつな人です。'
        'やまださんの　しゅみは　えいがを　みる　ことです。',
    passageVi: 'Tôi là Park, là nhân viên công ty. Từ thứ Hai đến thứ Sáu, '
        '7 giờ tôi đi tàu điện đến công ty. '
        'Tuần trước tôi có một người bạn mới. Tên người bạn là Yamada. '
        'Yamada là người tốt bụng. Sở thích của Yamada là xem phim.',
    picture: ExamPicture(
      emoji: '⌚',
      caption: 'とけい',
      hints: [
        'とけい',
        'にほんの　とけい 🇯🇵',
        'せんせいの',
        '９，０００えん',
      ],
    ),
    pictureQuestions: [
      'これは　なんですか。',
      'これは　だれの　とけいですか。',
      'いくらですか。',
    ],
    freeQuestion: 'まいあさ、なにを　たべますか。',
  ),
  Nihon1ExamSet(
    id: 'n1_3',
    title: 'Đề 3 · Đọc: Máy ảnh — Tranh: địa điểm (としょかん)',
    passage: 'これは　カメラです。ソニーの　カメラです。にほんの　カメラです。'
        'せんせいの　カメラです。２３，５００えんです。とても　いい　カメラです。'
        'わたしも　あたらしい　カメラが　ほしいです。でも、たかいですから、'
        'かいません。',
    passageVi: 'Đây là máy ảnh. Là máy ảnh của Sony. Là máy ảnh của Nhật Bản. '
        'Là máy ảnh của thầy/cô giáo. Giá 23.500 yên. Là máy ảnh rất tốt. '
        'Tôi cũng muốn có máy ảnh mới. Nhưng vì đắt nên tôi không mua.',
    picture: ExamPicture(
      emoji: '📚',
      caption: 'としょかん',
      hints: [
        'としょかん',
        '９じ　〜　１８じ',
        'げつようび　〜　きんようび',
        'やすみ：どようび・にちようび',
      ],
    ),
    pictureQuestions: [
      'ここは　どこですか。',
      'としょかんは　なんじから　なんじまでですか。',
      'やすみは　いつですか。',
    ],
    freeQuestion: 'やすみの　ひ、なにを　しますか。',
  ),
  Nihon1ExamSet(
    id: 'n1_4',
    title: 'Đề 4 · Đọc: Nhà hàng — Tranh: người (マイさん)',
    passage: 'ここは　レストランです。あさ　８じはんから　よる　４じはんまでです。'
        'やすみは　どようびと　にちようびです。この　レストランの　りょうりは　'
        'とても　おいしいです。わたしは　よく　ともだちと　ここで　ひるごはんを　'
        'たべます。',
    passageVi: 'Đây là nhà hàng. Mở cửa từ 8 giờ rưỡi sáng đến 4 giờ rưỡi chiều. '
        'Ngày nghỉ là thứ Bảy và Chủ nhật. Món ăn của nhà hàng này rất ngon. '
        'Tôi hay ăn trưa ở đây với bạn.',
    picture: ExamPicture(
      emoji: '👩‍🎓',
      caption: 'マイさん',
      hints: [
        'なまえ：マイ',
        '１９さい',
        'だいがくせい',
        'くに：ベトナム 🇻🇳',
        'しゅみ：えいが 🎬',
      ],
    ),
    pictureQuestions: [
      'マイさんは　なんさいですか。',
      'マイさんは　がくせいですか。',
      'マイさんの　しゅみは　なんですか。',
    ],
    freeQuestion: 'なんじに　おきますか。',
  ),
  Nihon1ExamSet(
    id: 'n1_5',
    title: 'Đề 5 · Đọc: Sinh hoạt hằng ngày — Tranh: đồ vật (かばん)',
    passage: 'わたしは　まいあさ　６じに　おきます。７じに　あさごはんを　たべます。'
        '８じに　がっこうへ　いきます。ごご、としょかんで　日本語を　べんきょうします。'
        'よる、うちで　テレビを　みます。そして、１１じに　ねます。',
    passageVi: 'Mỗi sáng tôi dậy lúc 6 giờ. 7 giờ ăn sáng. 8 giờ đi đến trường. '
        'Buổi chiều học tiếng Nhật ở thư viện. Buổi tối xem TV ở nhà. '
        'Rồi 11 giờ đi ngủ.',
    picture: ExamPicture(
      emoji: '🎒',
      caption: 'かばん',
      hints: [
        'かばん',
        'イタリアの　かばん 🇮🇹',
        'やまださんの',
        '２０，０００えん',
      ],
    ),
    pictureQuestions: [
      'これは　なんですか。',
      'これは　どこの　かばんですか。',
      'いくらですか。',
    ],
    freeQuestion: 'まいにち、コーヒーを　のみますか。',
  ),
];

/// Dựng [Scenario] cho màn Luyện nói từ một đề Nhật 1 đã bốc.
///
/// AI đóng vai GIÁM KHẢO, dùng NGUYÊN VĂN bài đọc / câu hỏi tranh / câu tự do
/// của đề (xem rule trong ai_conversation_service `_examPrompt`).
Scenario buildNihon1ExamScenario(Nihon1ExamSet set) => buildNihon1ScenarioRaw(
      id: 'nihon1_${set.id}',
      title: set.title,
      passage: set.passage,
      passageVi: set.passageVi,
      picture: set.picture,
      pictureQuestions: set.pictureQuestions,
      freeQuestion: set.freeQuestion,
    );

/// Lõi dựng [Scenario] Nhật 1 từ các trường thô — dùng chung cho đề cứng
/// ([Nihon1ExamSet]) và đề trên Firestore ([Nihon1Exam]).
Scenario buildNihon1ScenarioRaw({
  required String id,
  required String title,
  required String passage,
  required String passageVi,
  required ExamPicture picture,
  required List<String> pictureQuestions,
  required String freeQuestion,
}) {
  final pq = [
    for (var i = 0; i < pictureQuestions.length; i++)
      '${i + 1}) ${pictureQuestions[i]}',
  ].join('\n');
  return Scenario(
    id: id,
    emoji: '🟢',
    jpLabel: '日本語１',
    viLabel: title,
    drillType: ExamDrillType.nihon1,
    examPicture: picture,
    readingPassage: passage,
    readingPassageVi: passageVi,
    aiPersona: 'Bạn là GIÁM KHẢO kỳ thi nói tiếng Nhật học phần 1 (JPD113), '
        'trình độ sơ cấp N5. Thí sinh là người Việt. Thân thiện, khích lệ nhưng '
        'nghiêm túc như trong phòng thi.\n\n'
        'BÀI ĐỌC CỦA ĐỀ (thí sinh phải ĐỌC TO nguyên văn — KHÔNG hỏi về nội dung):\n'
        '$passage\n\n'
        'TRANH CỦA ĐỀ (thông tin ghi trên tranh — thí sinh nhìn tranh để trả lời):\n'
        '「${picture.caption}」: ${picture.hints.join('、')}\n\n'
        '3 CÂU HỎI THEO TRANH (hỏi đúng thứ tự, NGUYÊN VĂN):\n$pq\n\n'
        'CÂU HỎI TỰ DO — câu cuối cùng (NGUYÊN VĂN):\n$freeQuestion',
  );
}

/// Một đề thi Nhật 1 (JPD113) LƯU TRÊN FIRESTORE — giảng viên soạn/sửa qua
/// Admin (khác [Nihon1ExamSet] là 5 đề CỨNG trong code, chỉ dùng để seed).
///
/// Cấu trúc y hệt đề JPD113: bài đọc + 1 tranh (emoji·caption·hints) + 3 câu
/// theo tranh + 1 câu tự do. `published` = học viên bốc được (nháp thì ẩn).
class Nihon1Exam {
  final String id;
  String title;
  String passage;
  String passageVi;
  String pictureEmoji;
  String pictureCaption;
  List<String> pictureHints;
  List<String> pictureQuestions; // nên đúng 3 câu
  String freeQuestion;
  bool published;
  String updatedLabel;

  Nihon1Exam({
    required this.id,
    required this.title,
    this.passage = '',
    this.passageVi = '',
    this.pictureEmoji = '🖼️',
    this.pictureCaption = '',
    List<String>? pictureHints,
    List<String>? pictureQuestions,
    this.freeQuestion = '',
    this.published = false,
    this.updatedLabel = '',
  })  : pictureHints = pictureHints ?? [],
        pictureQuestions = pictureQuestions ?? ['', '', ''];

  ExamPicture get picture => ExamPicture(
        emoji: pictureEmoji.isEmpty ? '🖼️' : pictureEmoji,
        caption: pictureCaption,
        hints: pictureHints,
      );

  /// Dựng [Scenario] để đưa vào màn Luyện nói (AI làm giám khảo).
  Scenario toScenario() => buildNihon1ScenarioRaw(
        id: 'nihon1_$id',
        title: title,
        passage: passage,
        passageVi: passageVi,
        picture: picture,
        pictureQuestions: pictureQuestions,
        freeQuestion: freeQuestion,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'passage': passage,
        'passageVi': passageVi,
        'pictureEmoji': pictureEmoji,
        'pictureCaption': pictureCaption,
        'pictureHints': pictureHints,
        'pictureQuestions': pictureQuestions,
        'freeQuestion': freeQuestion,
        'published': published,
        'updatedLabel': updatedLabel,
      };

  factory Nihon1Exam.fromMap(String id, Map<String, dynamic> m) => Nihon1Exam(
        id: id,
        title: (m['title'] ?? '') as String,
        passage: (m['passage'] ?? '') as String,
        passageVi: (m['passageVi'] ?? '') as String,
        pictureEmoji: (m['pictureEmoji'] ?? '🖼️') as String,
        pictureCaption: (m['pictureCaption'] ?? '') as String,
        pictureHints: ((m['pictureHints'] as List?) ?? const []).cast<String>(),
        pictureQuestions:
            ((m['pictureQuestions'] as List?) ?? const []).cast<String>(),
        freeQuestion: (m['freeQuestion'] ?? '') as String,
        published: (m['published'] ?? false) as bool,
        updatedLabel: (m['updatedLabel'] ?? '') as String,
      );

  /// Tạo đề Firestore từ một đề cứng (dùng khi seed lần đầu).
  factory Nihon1Exam.fromSet(Nihon1ExamSet s) => Nihon1Exam(
        id: s.id,
        title: s.title,
        passage: s.passage,
        passageVi: s.passageVi,
        pictureEmoji: s.picture.emoji,
        pictureCaption: s.picture.caption,
        pictureHints: List<String>.from(s.picture.hints),
        pictureQuestions: List<String>.from(s.pictureQuestions),
        freeQuestion: s.freeQuestion,
        published: true, // 5 đề gốc coi như đã xuất bản
        updatedLabel: 'đề mẫu',
      );
}

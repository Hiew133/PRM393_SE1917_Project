import 'scenario.dart';

/// Đề thi nói Nhật 2 (JPD123) — format theo "Hướng dẫn thi Speaking JPD123"
/// của trường (100đ):
///
/// 1. **READING (45đ):** SV **đọc to** đoạn văn ~150 chữ (ngoài hiragana có
///    5–7 kanji, 2–4 katakana), chuẩn bị 20s.
/// 2. **Q&A (45đ = 3 câu × 15đ):** 1 câu hỏi theo TRANH + 2 câu hỏi KHÔNG
///    tranh.
/// 3. **Tác phong (10đ):** tác phong, độ trôi chảy, phát âm, chào hỏi.
///
/// Cấu trúc đề GIỐNG Nhật 1 (bốc 1 đề trọn gói là có cả bài đọc + Q&A) —
/// chỉ khác cơ cấu điểm và số câu hỏi (1 tranh + 2 tự do thay vì 3 tranh +
/// 1 tự do).
class Nihon2Exam {
  final String id;
  String title; // nhãn tiếng Việt, vd "Đề 1 · Đọc: Chuyến đi VN — Tranh: ✈️"
  String passage; // đoạn văn SV đọc to (~150 chữ)
  String passageVi; // dịch tiếng Việt
  String pictureEmoji;
  String pictureCaption;
  List<String> pictureHints;
  String pictureQuestion; // câu ① — trả lời dựa vào tranh
  String question2; // câu ② — không tranh
  String question3; // câu ③ — không tranh
  bool published;
  String updatedLabel;

  Nihon2Exam({
    required this.id,
    required this.title,
    this.passage = '',
    this.passageVi = '',
    this.pictureEmoji = '🖼️',
    this.pictureCaption = '',
    List<String>? pictureHints,
    this.pictureQuestion = '',
    this.question2 = '',
    this.question3 = '',
    this.published = false,
    this.updatedLabel = '',
  }) : pictureHints = pictureHints ?? [];

  ExamPicture get picture => ExamPicture(
        emoji: pictureEmoji.isEmpty ? '🖼️' : pictureEmoji,
        caption: pictureCaption,
        hints: pictureHints,
      );

  /// Dựng [Scenario] để đưa vào màn Luyện nói — AI đóng vai GIÁM KHẢO JPD123,
  /// dùng NGUYÊN VĂN bài đọc và 3 câu hỏi (xem rule trong
  /// ai_conversation_service `_exam123Prompt`).
  Scenario toScenario() => Scenario(
        id: 'nihon2_$id',
        emoji: '🔵',
        jpLabel: '日本語２',
        viLabel: title,
        drillType: ExamDrillType.nihon2,
        examPicture: picture,
        readingPassage: passage,
        readingPassageVi: passageVi,
        aiPersona:
            'Bạn là GIÁM KHẢO kỳ thi nói tiếng Nhật học phần 2 (JPD123), '
            'trình độ sơ cấp N5–N4. Thí sinh là người Việt. Thân thiện, khích '
            'lệ nhưng nghiêm túc như trong phòng thi.\n\n'
            'BÀI ĐỌC CỦA ĐỀ (thí sinh phải ĐỌC TO nguyên văn — KHÔNG hỏi về '
            'nội dung bài đọc):\n$passage\n\n'
            'TRANH CỦA ĐỀ (thí sinh nhìn thông tin trên tranh để trả lời '
            'CÂU HỎI 1):\n「$pictureCaption」: ${pictureHints.join('、')}\n\n'
            'CÂU HỎI 1 — THEO TRANH (nguyên văn):\n$pictureQuestion\n\n'
            'CÂU HỎI 2 — KHÔNG TRANH (nguyên văn):\n$question2\n\n'
            'CÂU HỎI 3 — KHÔNG TRANH (nguyên văn):\n$question3',
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'passage': passage,
        'passageVi': passageVi,
        'pictureEmoji': pictureEmoji,
        'pictureCaption': pictureCaption,
        'pictureHints': pictureHints,
        'pictureQuestion': pictureQuestion,
        'question2': question2,
        'question3': question3,
        'published': published,
        'updatedLabel': updatedLabel,
      };

  factory Nihon2Exam.fromMap(String id, Map<String, dynamic> m) => Nihon2Exam(
        id: id,
        title: (m['title'] ?? '') as String,
        passage: (m['passage'] ?? '') as String,
        passageVi: (m['passageVi'] ?? '') as String,
        pictureEmoji: (m['pictureEmoji'] ?? '🖼️') as String,
        pictureCaption: (m['pictureCaption'] ?? '') as String,
        pictureHints: ((m['pictureHints'] as List?) ?? const []).cast<String>(),
        pictureQuestion: (m['pictureQuestion'] ?? '') as String,
        question2: (m['question2'] ?? '') as String,
        question3: (m['question3'] ?? '') as String,
        published: (m['published'] ?? false) as bool,
        updatedLabel: (m['updatedLabel'] ?? '') as String,
      );
}

/// Đề mẫu (seed lần đầu). Đề 1 lấy nguyên văn từ đề demo chính thức
/// "JPD123 SPEAKING DEMO" (bài đọc A-0 + Q&A B-0); các đề sau soạn cùng cữ
/// (~150 chữ, 5–7 kanji, 2–4 katakana; câu hỏi từ danh sách ôn tập bài 4–7).
List<Nihon2Exam> buildNihon2ExamSeeds() => [
      Nihon2Exam(
        id: 'n2_1',
        title: 'Đề 1 · Đọc: Chuyến đi Việt Nam — Tranh: ✈️ どのくらい',
        passage: 'わたしは　今年の８月に　ベトナムへ　行きました。ハノイで　'
            'ともだちに　会いました。それから、いっしょに　ゆうめいな　'
            'きょうかいへ　行きました。とても　きれいでした。おいしい　'
            '食べ物も　たくさん　食べました。時間が　ありませんでしたから、'
            'ホーチミン市へ　行きませんでした。また　ホーチミン市へ　行きたいです。',
        passageVi: 'Tôi đã đến Việt Nam vào tháng 8 năm nay. Tôi gặp bạn ở Hà Nội. '
            'Sau đó chúng tôi cùng đến nhà thờ nổi tiếng. Nhà thờ rất đẹp. '
            'Tôi cũng ăn nhiều món ngon. Vì không có thời gian nên tôi chưa đi '
            'TP. Hồ Chí Minh. Tôi muốn đến TP. Hồ Chí Minh lần nữa.',
        pictureEmoji: '✈️',
        pictureCaption: 'ハノイ → ホーチミン',
        pictureHints: ['ひこうき ✈️', '２じかんはん'],
        pictureQuestion: 'ハノイから　ホーチミンまで　どのくらいですか。',
        question2: '今、何が　ほしいですか。',
        question3: '春と　夏と　どちらが　好きですか。',
        published: true,
        updatedLabel: 'đề mẫu',
      ),
      Nihon2Exam(
        id: 'n2_2',
        title: 'Đề 2 · Đọc: Trường đại học — Tranh: 📖 〜ています',
        passage: 'わたしの　大学は　ハノイに　あります。大学の　近くに　'
            'こうえんが　あります。まいにち、ともだちと　としょかんで　'
            '日本語を　べんきょうします。それから、カフェで　コーヒーを　'
            '飲みます。週まつは　うちで　アニメを　見ます。日本の　アニメは　'
            'とても　おもしろいです。',
        passageVi: 'Trường đại học của tôi ở Hà Nội. Gần trường có công viên. '
            'Mỗi ngày tôi học tiếng Nhật với bạn ở thư viện. Sau đó tôi uống '
            'cà phê ở quán cà phê. Cuối tuần tôi xem anime ở nhà. '
            'Anime Nhật Bản rất thú vị.',
        pictureEmoji: '📖',
        pictureCaption: 'リンさん',
        pictureHints: ['としょかんに　います', 'ほんを　よんでいます 📖'],
        pictureQuestion: 'リンさんは　何を　していますか。',
        question2: 'きのう、何を　しましたか。',
        question3: 'あなたの　まちは　どんな　ところですか。',
        published: true,
        updatedLabel: 'đề mẫu',
      ),
      Nihon2Exam(
        id: 'n2_3',
        title: 'Đề 3 · Đọc: Ngày Chủ nhật — Tranh: 🏦 どこにありますか',
        passage: 'きのうは　日曜日でしたから、かぞくと　スーパーへ　'
            '買い物に　行きました。くだものや　やさいを　たくさん　'
            '買いました。それから、レストランで　ひるごはんを　食べました。'
            'ぎゅうにくの　フォーは　おいしかったです。よる、うちで　'
            'えいがを　見ました。とても　たのしい　一日でした。',
        passageVi: 'Hôm qua là Chủ nhật nên tôi đi siêu thị mua sắm cùng gia đình. '
            'Tôi mua nhiều hoa quả và rau. Sau đó chúng tôi ăn trưa ở nhà hàng. '
            'Phở bò rất ngon. Buổi tối tôi xem phim ở nhà. '
            'Đó là một ngày rất vui.',
        pictureEmoji: '🏦',
        pictureCaption: 'ぎんこう',
        pictureHints: ['えきの　ちかく', 'ゆうびんきょくの　となり'],
        pictureQuestion: 'ぎんこうは　どこに　ありますか。',
        question2: '一年中で　何月が　いちばん　あついですか。',
        question3: '日本りょうりと　ベトナムりょうりと　どちらが　好きですか。',
        published: true,
        updatedLabel: 'đề mẫu',
      ),
    ];

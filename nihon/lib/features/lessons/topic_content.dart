/// Nội dung bài học theo chủ đề (Kinh tế / Chính trị / Văn hoá).
///
/// Viết cứng, trình độ ~N5: mỗi chủ đề gồm danh sách từ vựng + vài bài đọc
/// ngắn có dịch tiếng Việt. Có thể mở rộng sau.
class TopicVocab {
  final String word; // 経済
  final String reading; // けいざい
  final String meaning; // kinh tế
  const TopicVocab(this.word, this.reading, this.meaning);
}

class TopicReading {
  final String jp;
  final String vi;
  const TopicReading(this.jp, this.vi);
}

class TopicContent {
  final String titleVi;
  final String titleJp;
  final List<TopicVocab> vocab;
  final List<TopicReading> readings;
  const TopicContent({
    required this.titleVi,
    required this.titleJp,
    required this.vocab,
    required this.readings,
  });
}

const TopicContent kEconomyTopic = TopicContent(
  titleVi: 'Kinh tế',
  titleJp: '経済',
  vocab: [
    TopicVocab('お金', 'おかね', 'tiền'),
    TopicVocab('円', 'えん', 'yên (tiền Nhật)'),
    TopicVocab('経済', 'けいざい', 'kinh tế'),
    TopicVocab('会社', 'かいしゃ', 'công ty'),
    TopicVocab('仕事', 'しごと', 'công việc'),
    TopicVocab('銀行', 'ぎんこう', 'ngân hàng'),
    TopicVocab('買い物', 'かいもの', 'mua sắm'),
    TopicVocab('値段', 'ねだん', 'giá cả'),
    TopicVocab('高い', 'たかい', 'đắt, cao'),
    TopicVocab('安い', 'やすい', 'rẻ'),
  ],
  readings: [
    TopicReading(
      '日本のお金は円です。わたしはスーパーで買い物をします。このりんごは安いですが、あの車はとても高いです。',
      'Tiền của Nhật là yên. Tôi mua sắm ở siêu thị. Quả táo này rẻ, nhưng chiếc xe kia thì rất đắt.',
    ),
    TopicReading(
      'わたしは会社で働きます。毎月、銀行にお金をあずけます。日本の経済は大きいです。',
      'Tôi làm việc ở công ty. Mỗi tháng tôi gửi tiền vào ngân hàng. Nền kinh tế Nhật Bản rất lớn.',
    ),
  ],
);

const TopicContent kPoliticsTopic = TopicContent(
  titleVi: 'Chính trị',
  titleJp: '政治',
  vocab: [
    TopicVocab('政治', 'せいじ', 'chính trị'),
    TopicVocab('国', 'くに', 'đất nước'),
    TopicVocab('首都', 'しゅと', 'thủ đô'),
    TopicVocab('政府', 'せいふ', 'chính phủ'),
    TopicVocab('国民', 'こくみん', 'người dân, công dân'),
    TopicVocab('選挙', 'せんきょ', 'bầu cử'),
    TopicVocab('投票', 'とうひょう', 'bỏ phiếu'),
    TopicVocab('法律', 'ほうりつ', 'luật pháp'),
    TopicVocab('世界', 'せかい', 'thế giới'),
  ],
  readings: [
    TopicReading(
      '日本の首都は東京です。日本の政治の中心も東京にあります。',
      'Thủ đô của Nhật Bản là Tokyo. Trung tâm chính trị của Nhật cũng nằm ở Tokyo.',
    ),
    TopicReading(
      '国民は選挙で投票します。みんなで国のことを決めます。法律はとても大切です。',
      'Người dân bỏ phiếu trong các cuộc bầu cử. Mọi người cùng nhau quyết định việc của đất nước. Luật pháp rất quan trọng.',
    ),
  ],
);

const TopicContent kCultureTopic = TopicContent(
  titleVi: 'Văn hoá',
  titleJp: '文化',
  vocab: [
    TopicVocab('文化', 'ぶんか', 'văn hoá'),
    TopicVocab('伝統', 'でんとう', 'truyền thống'),
    TopicVocab('着物', 'きもの', 'kimono'),
    TopicVocab('祭り', 'まつり', 'lễ hội'),
    TopicVocab('花見', 'はなみ', 'ngắm hoa anh đào'),
    TopicVocab('神社', 'じんじゃ', 'đền thần'),
    TopicVocab('相撲', 'すもう', 'sumo'),
    TopicVocab('和食', 'わしょく', 'ẩm thực Nhật'),
    TopicVocab('お茶', 'おちゃ', 'trà'),
  ],
  readings: [
    TopicReading(
      '日本の伝統文化はとてもおもしろいです。春に花見をします。夏には祭りがたくさんあります。',
      'Văn hoá truyền thống Nhật Bản rất thú vị. Mùa xuân người ta đi ngắm hoa anh đào. Mùa hè có rất nhiều lễ hội.',
    ),
    TopicReading(
      '着物はきれいな日本の服です。神社でお参りをします。和食は健康にいいです。',
      'Kimono là trang phục đẹp của Nhật. Người ta đi lễ ở đền thần. Ẩm thực Nhật tốt cho sức khoẻ.',
    ),
  ],
);

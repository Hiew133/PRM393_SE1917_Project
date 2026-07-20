import 'dart:math';

import 'scenario.dart';

/// Đề thi nói Nhật 5 (JPD326) — format theo "Hướng dẫn ôn thi JPD326 Speaking"
/// của trường (100đ):
///
/// 1. **Role-play hội thoại 1-1 (60đ):** SV bốc 場面 và **KHÔNG được chọn vai**
///    (app gán ngẫu nhiên A hoặc B); AI đóng vai còn lại.
/// 2. **Trả lời 2 câu hỏi (30đ):** câu 1 (20đ) thuộc nội dung ôn tập đã chuẩn
///    bị trước, câu 2 (10đ) là câu phản xạ tại phòng thi.
/// 3. **Điểm thể hiện (10đ):** ngữ điệu, trọng âm, độ trôi chảy.
///
/// Nội dung bám giáo trình bài 6–10. Khác Nhật 1/Nhật 2 ở chỗ phần chính là
/// HỘI THOẠI NHIỀU LƯỢT (không phải mỗi lượt một câu hỏi cố định).

/// Một 場面 role-play: mô tả vai A và vai B.
class Jpd326Scene {
  final String id;
  final int lesson; // bài trong giáo trình (6, 7, 8, 10)
  final String title; // nhãn tiếng Việt ngắn gọn
  final String emoji;
  final String roleA; // nội dung vai A
  final String roleB; // nội dung vai B

  /// Thông tin kèm theo của vai (bảng "〜についての情報"), rỗng nếu không có.
  final List<String> roleAInfo;
  final List<String> roleBInfo;

  const Jpd326Scene({
    required this.id,
    required this.lesson,
    required this.title,
    required this.emoji,
    required this.roleA,
    required this.roleB,
    this.roleAInfo = const [],
    this.roleBInfo = const [],
  });

  String get label => '場面 $id（第$lesson課）';
}

/// Một câu hỏi phần 2 kèm gợi ý trả lời (không bắt buộc dùng).
class Jpd326Question {
  final int no;
  final int lesson;
  final String question; // nguyên văn câu hỏi tiếng Nhật
  final List<String> guides; // gợi ý ý cần nêu
  final String expressions; // 使われる言葉や文型・表現

  const Jpd326Question({
    required this.no,
    required this.lesson,
    required this.question,
    required this.guides,
    required this.expressions,
  });
}

/// 6 場面 role-play chính thức của đề JPD326.
const List<Jpd326Scene> kJpd326Scenes = [
  Jpd326Scene(
    id: '1',
    lesson: 6,
    emoji: '🍲',
    title: 'Khuyên bạn khi ăn không ngon miệng',
    roleA: '友達のBさんは体の調子が良くないようです。話を聞いて、どうしたらいいか、'
        'アドバイスしてください。よく言われている体にいい食べ物についても'
        '話してください。',
    roleB: 'あなたは、最近、あまり食欲がありません。季節が変わったために、'
        '体調を崩してしまったようです。友達のAさんにアドバイスをもらって'
        'ください。',
  ),
  Jpd326Scene(
    id: '2',
    lesson: 6,
    emoji: '😴',
    title: 'Khuyên bạn khi mất ngủ',
    roleA: '友達のBさんは具合が良くないようです。話を聞いて、どうしたらいいか、'
        'アドバイスしてください。寝られるようにいい方法についても'
        '話してください。',
    roleB: 'あなたは、最近、あまり寝られません。忙しくて、体調を崩してしまった'
        'ようです。友達のAさんにアドバイスをもらってください。',
  ),
  Jpd326Scene(
    id: '3',
    lesson: 7,
    emoji: '🛍️',
    title: 'Rủ bạn cùng mở gian hàng chợ trời',
    roleA: 'あなたは友達とフリーマーケットに出店することにしました。同じ英語の'
        'クラスに通っているBさんにも来てもらいたいです。Bさんとは時々挨拶する'
        'くらいです。クラスで会ったとき、フリーマーケットについて説明し、'
        '都合を聞いて、誘ってください。',
    roleAInfo: [
      '日時：来週の土曜日と日曜日　午前8時から',
      'このフリーマーケットには自分が作った料理を出してもいいです。',
      '商品の値段の2割がホームレスの寄付金になります。（ホームレス：Homeless）',
    ],
    roleB: 'あなたはAさんと同じ英語のクラスに通っています。Aさんとは時々クラスで'
        '挨拶するくらいです。Aさんが話しかけてきました。話をよく聞いて、'
        'Aさんの誘いを受けてください。',
  ),
  Jpd326Scene(
    id: '4',
    lesson: 7,
    emoji: '🤝',
    title: 'Rủ bạn tham gia hoạt động tình nguyện',
    roleA: 'あなたはボランティア活動に参加することにしました。同じ英語の中級'
        'クラスに通っているBさんにも来てもらいたいです。Bさんとは時々挨拶する'
        'くらいです。クラスで会ったとき、ボランティア活動について説明し、'
        '都合を聞いて、誘ってください。',
    roleAInfo: [
      '日時：毎週の土曜日　午前8時から10時まで',
      '地方の孤児院で子どもたちに初級レベルの英語を教える。（孤児院：cô nhi viện）',
      '活動に参加する人は後で英語の中級コースに無料で参加できる。',
    ],
    roleB: 'あなたはAさんと同じ英語の中級クラスに通っています。Aさんとは時々'
        'クラスで挨拶するくらいです。Aさんが話しかけてきました。話をよく聞いて、'
        'Aさんの誘いを受けてください。',
  ),
  Jpd326Scene(
    id: '5',
    lesson: 8,
    emoji: '🏪',
    title: 'Xin nghỉ phép với quản lý chỗ làm thêm',
    roleA: 'あなたはアルバイトをしています。来月末の1週間、友人が結婚するので、'
        'ふるさとへ帰りたいです。休みをもらえるように、店長に丁寧に'
        '頼んでください。',
    roleB: 'あなたは店長です。店は月末とても忙しいです。Aさんの話をよく聞いて、'
        'Aさんの代わりにアルバイトをやってもらう人がいるか確認してから、'
        '休む許可を出してください。',
  ),
  Jpd326Scene(
    id: '6',
    lesson: 10,
    emoji: '👛',
    title: 'Gọi điện hỏi đồ bỏ quên ở quán cà phê',
    roleA: 'あなたは喫茶店に財布を忘れました。帰りのバスの中で、そのことに'
        '気がつきました。喫茶店に電話をしてください。あなたは右の窓側の席に'
        '座りました。財布はテーブルの上に置いたと思いますが、はっきり覚えて'
        'いません。見つかったら、着払いの宅配便で送ってもらえるように'
        'お願いしてください。',
    roleAInfo: [
      '財布の情報：四角い・グレー・花模様がある・名前もつけてあります。'
          '（花模様：hình bông hoa）',
    ],
    roleB: 'あなたは喫茶店の店員です。忘れ物の問い合わせがあります。お客さんに、'
        '座った場所、忘れたものの特徴（色や形など）を聞いてください。'
        '聞いた場所を見たら、忘れ物がありました。お客さんにどうするか、'
        '聞いてください。',
  ),
];

/// Ngân hàng câu hỏi phần 2 (質問1) — bài 6→9.
const List<Jpd326Question> kJpd326Questions = [
  Jpd326Question(
    no: 1,
    lesson: 6,
    question: 'あなたが住んでいるところの地形について話してください。',
    guides: [
      'あなたはどこに住んでいますか。',
      '住むところの面積、地形の特徴（平野か山地か）などを述べなさい。',
    ],
    expressions: '〜分の〜／南北・北西など／山林・島・湖・山・港・浜／'
        '〜が広がっています／〜に山が連なっています／〜を川が流れています／'
        '町の中心に〜があります／〜は〜に接しています／〜は〜に面しています／'
        '〜は〜に位置しています／〜に恵まれています',
  ),
  Jpd326Question(
    no: 2,
    lesson: 6,
    question: 'あなたの町にどんな行事がありますか。その行事を紹介してください。',
    guides: [
      'あなたの町にどんな行事がありますか。',
      'その行事の行う時点、活動、目的など、1つか2つの具体的な情報を話してください。',
    ],
    expressions: '〜と言えば／〜というと、〜が有名です・盛んです／知られています／'
        '（毎年〜月になると／近年）、〜が行われています／開催される／'
        '〜が見られます／〜が味わえます／〜が楽しめます',
  ),
  Jpd326Question(
    no: 3,
    lesson: 7,
    question: '大学のあるクラブに参加する前に、どうやってそのクラブの情報を'
        '調べましたか。あなたは自分の経験を話してください。',
    guides: [
      'あなたはどのクラブに入りましたか。',
      'そのクラブに参加する前にどこから情報を調べたか詳しく話してください。',
    ],
    expressions: '友だち、大学のサイトなどから〜わかりました／知りました／'
        '〜に入りました／〜を聞きました／レビュー／感想',
  ),
  Jpd326Question(
    no: 4,
    lesson: 7,
    question: '今までどんなボランティアや活動に参加しましたか。参加して感じたこと、'
        '考えたことを話してください。',
    guides: [
      'どんな活動に参加したのか。',
      '感想についての表現・言葉を使うかどうか。',
    ],
    expressions: '〜たところ〜ました／でした。ところが、〜ました／'
        '思ったより〜　意外と〜　予想と違って／予想通り〜　期待通り〜　実際は〜／'
        '出会う・知り合う・緊張する・体験する・話しかける・触れる・驚く・'
        '実感する・見つめ直す・視野が広がる・努力する・寄付する・期待する・'
        '感動する・共通する・気がする・育成する／貴重（な）・新鮮（な）・'
        '充実した・違和感・体験談・友人・お互い・寄付金・〜同士・素晴らしい・'
        'うらやましい',
  ),
  Jpd326Question(
    no: 5,
    lesson: 8,
    question: 'あなたは人に「ごめんなさい」という時、直接言いますか、それとも'
        'メッセージですか。どうしてですか。',
    guides: [
      'どうやって「ごめんなさい」という言葉を伝えますか。',
      'どうしてですか。',
    ],
    expressions: '〜たびに／当然／意外（な）／ただ／〜ば／〜なら（ば）／'
        '〜たら、〜たのに／〜（さ）せる／〜てしまう／'
        '実感する／緊張する／判断する／思い切って',
  ),
  Jpd326Question(
    no: 6,
    lesson: 8,
    question: '人から悩みをシェアしてもらったことがありますか。そのとき、'
        'あなたの気持ちはどうでしたか。',
    guides: [
      '悩みをシェアしてもらったことがありますか。',
      'なぜだと思いますか。',
    ],
    expressions: '違和感・緊張する・嬉しい・心配する・困る・感謝する・驚く・'
        '実感する・〜かどうか・気がする／〜くせに／〜せいで・おかげで／'
        '〜させる　など',
  ),
  Jpd326Question(
    no: 7,
    lesson: 9,
    question: '一番好きな日本語の言葉を教えてください。理由も説明してください。',
    guides: [
      '日本語の言葉を教えてください。',
      '理由を教えてください。',
    ],
    expressions: '〜ほど・ぐらい・くらい／〜がたい・〜が印象的でした／'
        '〜が心に残っています／〜を基にして／〜とともに／〜ように／'
        '〜が印象に残っています／〜に感動しました／〜に励まされました／'
        '〜に驚きました／〜ショックを受けました／〜ように感じました／思いました',
  ),
];

/// Một ĐỀ JPD326 đã bốc: 1 場面 + vai được gán + 2 câu hỏi.
class Jpd326Exam {
  final Jpd326Scene scene;

  /// Vai của THÍ SINH: true = vai A, false = vai B. Đề thi quy định thí sinh
  /// KHÔNG được chọn vai nên app bốc ngẫu nhiên.
  final bool studentIsA;
  final Jpd326Question question1; // 20đ — nội dung ôn tập
  final Jpd326Question question2; // 10đ — câu phản xạ

  const Jpd326Exam({
    required this.scene,
    required this.studentIsA,
    required this.question1,
    required this.question2,
  });

  /// Bốc ngẫu nhiên một đề: 場面 bất kỳ, vai ngẫu nhiên, 2 câu hỏi khác nhau.
  factory Jpd326Exam.draw([Random? rng]) {
    final r = rng ?? Random();
    final scene = kJpd326Scenes[r.nextInt(kJpd326Scenes.length)];
    final pool = List<Jpd326Question>.from(kJpd326Questions)..shuffle(r);
    return Jpd326Exam(
      scene: scene,
      studentIsA: r.nextBool(),
      question1: pool[0],
      question2: pool[1],
    );
  }

  /// Bốc đề với 場面 chỉ định (SV chọn 場面 nhưng vẫn không chọn vai).
  factory Jpd326Exam.forScene(Jpd326Scene scene, [Random? rng]) {
    final r = rng ?? Random();
    final pool = List<Jpd326Question>.from(kJpd326Questions)..shuffle(r);
    return Jpd326Exam(
      scene: scene,
      studentIsA: r.nextBool(),
      question1: pool[0],
      question2: pool[1],
    );
  }

  String get studentRoleLabel => studentIsA ? 'A' : 'B';
  String get aiRoleLabel => studentIsA ? 'B' : 'A';
  String get studentRoleText => studentIsA ? scene.roleA : scene.roleB;
  String get aiRoleText => studentIsA ? scene.roleB : scene.roleA;
  List<String> get studentRoleInfo =>
      studentIsA ? scene.roleAInfo : scene.roleBInfo;
  List<String> get aiRoleInfo => studentIsA ? scene.roleBInfo : scene.roleAInfo;

  String get title => '${scene.label} · ${scene.title}';

  /// Dựng [Scenario] cho màn Luyện nói — AI đóng vai đối phương trong role-play
  /// rồi hỏi 2 câu (xem rule trong ai_conversation_service `_exam326Prompt`).
  Scenario toScenario() {
    String infoBlock(List<String> info) =>
        info.isEmpty ? '' : '\n情報：\n- ${info.join('\n- ')}';
    return Scenario(
      id: 'jpd326_${scene.id}_${studentIsA ? 'A' : 'B'}',
      emoji: '🟠',
      jpLabel: '日本語５',
      viLabel: title,
      drillType: ExamDrillType.jpd326,
      rolePlayCard: studentRoleText,
      rolePlayCardInfo: studentRoleInfo,
      rolePlayRoleLabel: studentRoleLabel,
      aiPersona:
          'Bạn là GIÁM KHẢO kỳ thi nói tiếng Nhật JPD326 (trình độ trung cấp, '
          'giáo trình bài 6–10). Thí sinh là người Việt.\n\n'
          'PHẦN 1 — ROLE-PLAY (${scene.label}):\n'
          'BẠN đóng vai $aiRoleLabel: $aiRoleText${infoBlock(aiRoleInfo)}\n\n'
          'THÍ SINH đóng vai $studentRoleLabel: '
          '$studentRoleText${infoBlock(studentRoleInfo)}\n\n'
          'PHẦN 2 — CÂU HỎI 1 (nguyên văn): ${question1.question}\n'
          'PHẦN 2 — CÂU HỎI 2 (nguyên văn): ${question2.question}',
    );
  }
}

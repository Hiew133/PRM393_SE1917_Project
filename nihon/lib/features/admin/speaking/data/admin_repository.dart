import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../speaking/models/nihon1_exam_sets.dart';
import '../../../speaking/models/nihon2_exam_sets.dart';
import '../models/admin_models.dart';

/// Kho dữ liệu admin trên **Cloud Firestore**.
///
/// MỖI ĐỀ có nội dung RIÊNG: mỗi tình huống/câu hỏi mang [examId]. Tạo đề mới
/// sẽ nhân bản "bộ khung" (3 mẫu hội thoại + 17 câu) cho đề đó để sửa độc lập.
/// Collections: `exams`, `situations`, `questions` (lọc theo examId).
class AdminRepository extends ChangeNotifier {
  AdminRepository._() {
    _init();
  }
  static final AdminRepository instance = AdminRepository._();

  // Dự án dùng Firestore database TÊN 'default' (named database), KHÔNG phải
  // database mặc định '(default)'. Bắt buộc chỉ rõ databaseId, nếu không sẽ lỗi
  // NOT_FOUND: "database (default) does not exist for project ...".
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  // Gom TẤT CẢ dữ liệu của app vào dưới 1 document 'speaking/app' để tách khỏi
  // dữ liệu app khác dùng chung database (vd collection 'vocabulary').
  // Mọi collection thành subcollection: speaking/app/exams, .../meta, ...
  DocumentReference<Map<String, dynamic>> get _root =>
      _db.collection('speaking').doc('app');

  final List<Exam> exams = [];
  final List<QaQuestion> questions = [];
  final List<ConversationSituation> situations = [];
  final List<StudentScore> scores = [];
  final List<Nihon1Exam> nihon1Exams = []; // đề thi Nhật 1 (JPD113)
  final List<Nihon2Exam> nihon2Exams = []; // đề thi Nhật 2 (JPD123)

  bool ready = false;
  String? error;

  // Snapshot ĐẦU TIÊN của từng collection đã về chưa — [ready] chỉ bật khi đủ
  // cả 6 (trước đây chỉ theo `exams` nên các list khác có thể vẫn rỗng).
  final Set<String> _loadedCols = {};
  static const int _kColCount = 6;
  void _markLoaded(String col) {
    _loadedCols.add(col);
    ready = _loadedCols.length >= _kColCount;
  }

  /// Hoàn thành khi dữ liệu đã về lần đầu (repo khởi tạo LAZY nên ngay sau lần
  /// truy cập đầu tiên các list còn rỗng vài trăm ms — đợi ở đây trước khi kết
  /// luận "chưa có đề"). Cũng hoàn thành khi gặp lỗi hoặc quá [timeout] để UI
  /// không treo loading vô hạn.
  Future<void> whenReady({Duration timeout = const Duration(seconds: 10)}) {
    if (ready || error != null) return Future.value();
    final done = Completer<void>();
    void check() {
      if ((ready || error != null) && !done.isCompleted) done.complete();
    }

    addListener(check);
    return done.future
        .timeout(timeout, onTimeout: () {})
        .whenComplete(() => removeListener(check));
  }

  CollectionReference<Map<String, dynamic>> get _examsCol =>
      _root.collection('exams');
  CollectionReference<Map<String, dynamic>> get _questionsCol =>
      _root.collection('questions');
  CollectionReference<Map<String, dynamic>> get _situationsCol =>
      _root.collection('situations');
  CollectionReference<Map<String, dynamic>> get _scoresCol =>
      _root.collection('scores');
  CollectionReference<Map<String, dynamic>> get _nihon1Col =>
      _root.collection('nihon1_exams');
  CollectionReference<Map<String, dynamic>> get _nihon2Col =>
      _root.collection('nihon2_exams');

  static const List<RubricCriterion> rubric = [
    RubricCriterion(
        id: 'kaiwa_grammar',
        label: 'Dùng đúng 文法 yêu cầu',
        hint: 'Các mẫu ngữ pháp bắt buộc của tình huống',
        maxPoints: 20),
    RubricCriterion(
        id: 'kaiwa_solve', label: 'Giải quyết tình huống', maxPoints: 15),
    RubricCriterion(
        id: 'kaiwa_pronun', label: 'Phát âm · trôi chảy', maxPoints: 10),
    RubricCriterion(
        id: 'kaiwa_keigo', label: 'Kính ngữ · tự nhiên', maxPoints: 10),
    RubricCriterion(
        id: 'qa_g1', label: 'Có tranh', maxPoints: 15, qaGroup: QaGroup.withImage),
    RubricCriterion(
        id: 'qa_g2', label: 'Không tranh', maxPoints: 15, qaGroup: QaGroup.noImage),
    RubricCriterion(
        id: 'qa_g3', label: 'Tự do', maxPoints: 15, qaGroup: QaGroup.free),
  ];

  // ── Truy vấn theo ĐỀ (lọc trên cache cục bộ) ───────────
  List<QaQuestion> questionsForExam(String examId, [QaGroup? g]) {
    final list = questions
        .where((q) => q.examId == examId && (g == null || q.group == g))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<ConversationSituation> situationsForExam(String examId,
      [String? template]) {
    return situations
        .where((s) =>
            s.examId == examId && (template == null || s.baseTemplate == template))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  List<String> templatesForExam(String examId) => situations
      .where((s) => s.examId == examId)
      .map((s) => s.baseTemplate)
      .toSet()
      .toList()
    ..sort();

  // ── Khởi tạo ───────────────────────────────────────────
  /// Tăng số này khi đổi cấu trúc seed → app tự dọn nội dung cũ & seed lại.
  /// v3: mỗi đề chỉ còn 1 tình huống + 3 câu (1 mỗi nhóm) — bỏ khung 9+17.
  static const int _seedVersion = 3;

  Future<void> _init() async {
    try {
      await _seedOrMigrate();
    } catch (e) {
      error = 'Lỗi Firestore khi seed: $e';
      notifyListeners();
    }
    _examsCol.snapshots().listen((snap) {
      exams
        ..clear()
        ..addAll(snap.docs.map((d) => Exam.fromMap(d.id, d.data())));
      _markLoaded('exams');
      notifyListeners();
    }, onError: _onErr);
    _questionsCol.snapshots().listen((snap) {
      questions
        ..clear()
        ..addAll(snap.docs.map((d) => QaQuestion.fromMap(d.id, d.data())));
      _markLoaded('questions');
      notifyListeners();
    }, onError: _onErr);
    _situationsCol.snapshots().listen((snap) {
      situations
        ..clear()
        ..addAll(
            snap.docs.map((d) => ConversationSituation.fromMap(d.id, d.data())));
      _markLoaded('situations');
      notifyListeners();
    }, onError: _onErr);
    _scoresCol.snapshots().listen((snap) {
      scores
        ..clear()
        ..addAll(snap.docs.map((d) => StudentScore.fromMap(d.id, d.data())));
      _markLoaded('scores');
      notifyListeners();
    }, onError: _onErr);
    _nihon1Col.snapshots().listen((snap) {
      nihon1Exams
        ..clear()
        ..addAll(snap.docs.map((d) => Nihon1Exam.fromMap(d.id, d.data())));
      _markLoaded('nihon1');
      notifyListeners();
    }, onError: _onErr);
    _nihon2Col.snapshots().listen((snap) {
      nihon2Exams
        ..clear()
        ..addAll(snap.docs.map((d) => Nihon2Exam.fromMap(d.id, d.data())));
      _markLoaded('nihon2');
      notifyListeners();
    }, onError: _onErr);
  }

  void _onErr(Object e, StackTrace st) {
    error = 'Lỗi Firestore: $e';
    notifyListeners();
  }

  Future<void> _seedOrMigrate() async {
    final metaRef = _root.collection('meta').doc('admin');
    final meta = await metaRef.get();
    final ver = (meta.data()?['seedVersion'] ?? 0) as int;

    // 1) Đảm bảo có sẵn các đề mẫu (chỉ khi chưa có đề nào).
    var examDocs = (await _examsCol.get()).docs;
    if (examDocs.isEmpty) {
      final b = _db.batch();
      for (final e in _seedExams()) {
        b.set(_examsCol.doc(e.id), e.toMap());
      }
      await b.commit();
      examDocs = (await _examsCol.get()).docs;
    }

    // 1b) Seed đề Nhật 1 (JPD113) từ 5 đề cứng — chỉ khi collection còn rỗng.
    if ((await _nihon1Col.get()).docs.isEmpty) {
      final b = _db.batch();
      for (final s in kNihon1ExamSets) {
        b.set(_nihon1Col.doc(s.id), Nihon1Exam.fromSet(s).toMap());
      }
      await b.commit();
    }

    // 1c) Seed đề Nhật 2 (JPD123) — chỉ khi collection còn rỗng. Nhân tiện
    //     dọn 2 collection tạm của bản thiết kế cũ (đề đọc/Q&A tách đôi) nếu
    //     còn sót lại từ lần chạy trước.
    if ((await _nihon2Col.get()).docs.isEmpty) {
      final b = _db.batch();
      for (final e in buildNihon2ExamSeeds()) {
        b.set(_nihon2Col.doc(e.id), e.toMap());
      }
      await b.commit();
      await _wipe(_root.collection('nihon2_readings'));
      await _wipe(_root.collection('nihon2_qa'));
    }

    if (ver >= _seedVersion) return; // đã seed/migrate theo định dạng mới

    // 2) Migrate: dọn nội dung cũ (không có examId) & nhân bản bộ khung cho
    //    từng đề hiện có. Giữ nguyên danh sách đề.
    await _wipe(_questionsCol);
    await _wipe(_situationsCol);
    for (var i = 0; i < examDocs.length; i++) {
      final id = examDocs[i].id;
      final b = _db.batch();
      // Mỗi đề mẫu seed một tình huống khác nhau (1.1/2.1/3.1) cho có biến thể.
      for (final s in _cloneSituations(id, sample: i)) {
        b.set(_situationsCol.doc(s.id), s.toMap());
      }
      for (final q in _cloneQuestions(id)) {
        b.set(_questionsCol.doc(q.id), q.toMap());
      }
      await b.commit();
    }
    await metaRef.set({'seedVersion': _seedVersion});
  }

  Future<void> _wipe(CollectionReference<Map<String, dynamic>> col) async {
    final snap = await col.get();
    for (var i = 0; i < snap.docs.length; i += 400) {
      final b = _db.batch();
      for (final d in snap.docs.skip(i).take(400)) {
        b.delete(d.reference);
      }
      await b.commit();
    }
  }

  // ── ĐỀ ─────────────────────────────────────────────────
  Future<Exam> createExam(
      {required String title, required String lessonRange}) async {
    final id = 'exam_${DateTime.now().millisecondsSinceEpoch}';
    final exam = Exam(
      id: id,
      title: title.trim(),
      lessonRange: lessonRange.trim().isEmpty ? 'Bài 1~5' : lessonRange.trim(),
      status: ExamStatus.draft,
      updatedLabel: 'vừa tạo',
    );
    final batch = _db.batch();
    batch.set(_examsCol.doc(id), exam.toMap());
    // Nhân bản bộ khung (3 mẫu × 3 + 17 câu) cho đề mới.
    for (final s in _cloneSituations(id)) {
      batch.set(_situationsCol.doc(s.id), s.toMap());
    }
    for (final q in _cloneQuestions(id)) {
      batch.set(_questionsCol.doc(q.id), q.toMap());
    }
    await batch.commit();
    return exam;
  }

  Future<void> saveExam(Exam exam,
      {String? title, String? lessonRange, ExamStatus? status}) async {
    if (title != null && title.trim().isNotEmpty) exam.title = title.trim();
    if (lessonRange != null && lessonRange.trim().isNotEmpty) {
      exam.lessonRange = lessonRange.trim();
    }
    if (status != null) exam.status = status;
    exam.updatedLabel = 'vừa cập nhật';
    await _examsCol.doc(exam.id).set(exam.toMap());
  }

  Future<void> updateExamStatus(Exam exam, ExamStatus status) async {
    exam.status = status;
    exam.updatedLabel = 'vừa cập nhật';
    await _examsCol.doc(exam.id).update(
        {'status': status.name, 'updatedLabel': exam.updatedLabel});
  }

  /// Xoá đề + toàn bộ tình huống & câu hỏi của đề đó.
  Future<void> deleteExam(Exam exam) async {
    final batch = _db.batch();
    batch.delete(_examsCol.doc(exam.id));
    for (final s in situations.where((s) => s.examId == exam.id)) {
      batch.delete(_situationsCol.doc(s.id));
    }
    for (final q in questions.where((q) => q.examId == exam.id)) {
      batch.delete(_questionsCol.doc(q.id));
    }
    await batch.commit();
  }

  // ── ĐỀ NHẬT 1 (JPD113) ─────────────────────────────────
  /// Các đề Nhật 1 đã xuất bản (học viên bốc được).
  List<Nihon1Exam> get publishedNihon1Exams =>
      nihon1Exams.where((e) => e.published).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  Future<Nihon1Exam> createNihon1Exam({required String title}) async {
    final id = 'nex_${DateTime.now().millisecondsSinceEpoch}';
    final exam = Nihon1Exam(
      id: id,
      title: title.trim().isEmpty ? 'Đề Nhật 1 mới' : title.trim(),
      updatedLabel: 'vừa tạo',
    );
    await _nihon1Col.doc(id).set(exam.toMap());
    return exam;
  }

  Future<void> saveNihon1Exam(Nihon1Exam e) async {
    e.updatedLabel = 'vừa cập nhật';
    await _nihon1Col.doc(e.id).set(e.toMap());
  }

  Future<void> setNihon1Published(Nihon1Exam e, bool published) async {
    e.published = published;
    e.updatedLabel = 'vừa cập nhật';
    await _nihon1Col.doc(e.id).update(
        {'published': published, 'updatedLabel': e.updatedLabel});
  }

  Future<void> deleteNihon1Exam(Nihon1Exam e) =>
      _nihon1Col.doc(e.id).delete();

  // ── ĐỀ NHẬT 2 (JPD123) ─────────────────────────────────
  /// Các đề Nhật 2 đã xuất bản (học viên bốc được).
  List<Nihon2Exam> get publishedNihon2Exams =>
      nihon2Exams.where((e) => e.published).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  Future<Nihon2Exam> createNihon2Exam({required String title}) async {
    final id = 'n2_${DateTime.now().millisecondsSinceEpoch}';
    final exam = Nihon2Exam(
      id: id,
      title: title.trim().isEmpty ? 'Đề Nhật 2 mới' : title.trim(),
      updatedLabel: 'vừa tạo',
    );
    await _nihon2Col.doc(id).set(exam.toMap());
    return exam;
  }

  Future<void> saveNihon2Exam(Nihon2Exam e) async {
    e.updatedLabel = 'vừa cập nhật';
    await _nihon2Col.doc(e.id).set(e.toMap());
  }

  Future<void> deleteNihon2Exam(Nihon2Exam e) => _nihon2Col.doc(e.id).delete();

  // ── CÂU HỎI Q&A ────────────────────────────────────────
  /// Tạo doc id mới cho câu hỏi của một đề.
  String newQuestionId(String examId) =>
      '${examId}__q_${DateTime.now().millisecondsSinceEpoch}';

  int nextQuestionOrder(String examId) {
    final list = questionsForExam(examId);
    return list.isEmpty ? 1 : list.last.order + 1;
  }

  Future<void> saveQuestion(QaQuestion q) =>
      _questionsCol.doc(q.id).set(q.toMap());

  Future<void> deleteQuestion(QaQuestion q) async {
    if (q.imageUrl != null) await _deleteQaImage(q.examId, q.id);
    await _questionsCol.doc(q.id).delete();
  }

  // ── ẢNH câu hỏi có tranh (Firebase Storage) ────────────
  Reference _qaImageRef(String examId, String questionId) =>
      FirebaseStorage.instance.ref('qa_images/$examId/$questionId.jpg');

  /// Upload ảnh (bytes) cho câu hỏi → trả URL tải về để lưu vào [QaQuestion].
  Future<String> uploadQaImage(
      String examId, String questionId, Uint8List bytes) async {
    final ref = _qaImageRef(examId, questionId);
    await ref.putData(
        bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> _deleteQaImage(String examId, String questionId) async {
    try {
      await _qaImageRef(examId, questionId).delete();
    } catch (_) {
      // Ảnh có thể đã bị xoá / chưa tồn tại — bỏ qua.
    }
  }

  // ── TÌNH HUỐNG 会話 ────────────────────────────────────
  Future<void> saveSituation(ConversationSituation s) =>
      _situationsCol.doc(s.id).set(s.toMap());

  // ── ĐIỂM SINH VIÊN (chấm thi S06) ──────────────────────
  String newScoreId(String examId) =>
      '${examId}__sc_${DateTime.now().millisecondsSinceEpoch}';

  List<StudentScore> scoresForExam(String examId) => scores
      .where((s) => s.examId == examId)
      .toList()
    ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

  /// Lưu điểm 1 SV rồi cập nhật thống kê đề (số SV đã thi + điểm TB).
  Future<void> saveScore(StudentScore s) async {
    await _scoresCol.doc(s.id).set(s.toMap());
    await _refreshExamStats(s.examId);
  }

  Future<void> _refreshExamStats(String examId) async {
    final snap = await _scoresCol.where('examId', isEqualTo: examId).get();
    final totals =
        snap.docs.map((d) => (d.data()['total'] ?? 0) as int).toList();
    final taken = totals.length;
    final avg = taken == 0
        ? 0
        : (totals.reduce((a, b) => a + b) / taken).round();
    await _examsCol.doc(examId).update({
      'studentsTaken': taken,
      'avgScore': avg,
      'updatedLabel': 'vừa chấm',
    });
  }

  // ── Seed / nhân bản bộ khung ───────────────────────────
  List<Exam> _seedExams() => [
        Exam(
            id: 'final_a',
            title: 'Thi cuối kỳ JPD316 — Đề A',
            lessonRange: 'Bài 1~5',
            status: ExamStatus.published,
            updatedLabel: '2 ngày trước',
            studentsTaken: 142,
            avgScore: 78),
        Exam(
            id: 'final_b',
            title: 'Thi cuối kỳ JPD316 — Đề B',
            lessonRange: 'Bài 1~5',
            status: ExamStatus.draft,
            updatedLabel: 'hôm nay'),
        Exam(
            id: 'mid',
            title: 'Thi giữa kỳ JPD316',
            lessonRange: 'Bài 1~3',
            status: ExamStatus.archived,
            updatedLabel: 'đã đóng',
            studentsTaken: 156,
            avgScore: 81),
      ];

  /// MỘT tình huống 会話 cho 1 đề (id `<examId>__s1`). [sample] chọn 1 trong 3
  /// mẫu gốc (1.1/2.1/3.1) — dùng để 3 đề mẫu ra 3 tình huống khác nhau; đề
  /// tạo mới mặc định lấy mẫu 会話1.1. Biến thể giữa các SV nay lấy từ NHIỀU đề.
  List<ConversationSituation> _cloneSituations(String examId, {int sample = 0}) {
    final sid = '${examId}__s1';
    const g11 = ['〜よね', '〜とか〜とか', '〜だけ'];
    const g21 = ['〜てもらえませんか', '〜ということだ', '〜でしょうか'];
    const g31 = ['〜そうにないんですが', '〜とか（で）'];

    final samples = <ConversationSituation>[
      ConversationSituation(
        id: sid,
        examId: examId,
        baseTemplate: '会話1.1',
        title: 'Rủ bạn đi workshop trải nghiệm văn hoá Nhật',
        grammar: List.of(g11),
        changeNote: 'Đổi loại sự kiện / hoạt động / điều kiện',
        drafted: true,
        scenarioStudent:
            '大学の掲示板（けいじばん）で日本文化体験ワークショップのお知らせを見つけました。'
            '友達にイベントの内容を説明して、誘ってください。'
            '友達は以前から日本文化を体験したいと言っていました。',
        scenarioTeacher:
            '日本文化体験ワークショップに誘われました。どんな内容のイベントか聞いてください。',
        sample: const [
          DialogueLine('S', '掲示板のお知らせ見た？'),
          DialogueLine('T', 'うん、まだ。何かおもしろそうなイベントあった？'),
          DialogueLine('S', 'うん。来週、＿＿があるんだって。一緒に行ってみない？'),
          DialogueLine('T', '＿＿かあ。'),
          DialogueLine('S',
              'うん。マリヤムさん、＿＿って言ってたよね。＿＿って書いてあるし、とてもいい機会だと思うよ。'),
          DialogueLine('T', 'うーん、行ってみたいけど……。どんなことするの？'),
          DialogueLine(
              'S', '＿＿とか＿＿とかを一緒にしたり、＿＿を教えてもらえたりするらしいよ。'),
          DialogueLine('T', 'ふーん。'),
          DialogueLine('S', '＿＿たらラッキーだし、行ってみようよ。'),
          DialogueLine('T', 'そうだね。じゃ、行ってみようかな……。'),
          DialogueLine('S',
              'そうだよ。行こうよ。定員があるから、行くならできるだけ早く申し込んだほうがいいらしいよ。'),
          DialogueLine('T', 'そっか。じゃ、行くかどうかできるだけ早く決めるね。'),
        ],
      ),
      ConversationSituation(
        id: sid,
        examId: examId,
        baseTemplate: '会話2.1',
        title: 'Nhờ sửa lai quần jeans, muốn lấy sớm',
        grammar: List.of(g21),
        changeNote: 'Đổi món đồ / thời gian / phụ phí',
        drafted: true,
        scenarioStudent:
            'あなたはジーンズを買いに来ました。試着室ではいてみましたが、すそが長いので、'
            '店の人に頼んで長さを直してもらってください。'
            'あなたは今日用事があるので、できるだけ早くジーンズを受け取って帰りたいと思っています。',
        scenarioTeacher:
            'あなたは店員です。お客さんがジーンズを試着しました。お客さんの希望を聞いてください。'
            'いつもジーンズの裾（すそ）を直すのに1時間ですが、今日は混んでいるので2時間くらいかかります。'
            '早く直すときには特別料金（200円）がかかります。',
        sample: const [
          DialogueLine('S', 'すみません。'),
          DialogueLine('T', 'いかがですか。'),
          DialogueLine('S', 'ちょっと＿＿ので、＿＿てもらえませんか。'),
          DialogueLine('T', 'はい、かしこまりました。'),
          DialogueLine('S', 'あのう、どのくらい時間がかかりますか。'),
          DialogueLine('T',
              'そうですね。いつもは＿＿くらいなんですが、今日は混んでいるので、＿＿ほど待っていただいているんですが……。'),
          DialogueLine(
              'S', '＿＿ですか。じゃ、今、＿＿だから、＿＿になるということですね。'),
          DialogueLine('T', 'ええ。＿＿になります。'),
          DialogueLine('S',
              'そうですか。あのう、ちょっと急いでいるので、＿＿ごろに受け取ることはできないでしょうか。'),
          DialogueLine('T', 'お急ぎのときには、特別料金をいただくことになっているんですが……。'),
          DialogueLine('S', 'あ、いくらですか。'),
          DialogueLine('T', '特別料金は＿＿いただいています。'),
          DialogueLine('S', 'そうですか。じゃ、お願いします。'),
        ],
      ),
      ConversationSituation(
        id: sid,
        examId: examId,
        baseTemplate: '会話3.1',
        title: 'Gọi điện báo trễ phỏng vấn (tàu dừng vì động đất)',
        grammar: List.of(g31),
        changeNote: '地震→台風 · 面接→打ち合わせ · đổi giờ hẹn',
        drafted: true,
        scenarioStudent:
            'あなたは留学生で、今日、アルバイトの面接があります。'
            'しかし、駅に着いたら電車が止まっていました。駅のアナウンスでは地震の影響だと言っています。'
            '電車はいつ動くか分かりません。面接に行くのに方法がありません。'
            '店長に電話で今の状況を話して、どうしたらいいか聞いてください。',
        scenarioTeacher:
            'あなたは店長で、今日アルバイトの面接を受ける予定になっていた留学生から電話がありました。'
            '話を聞いて、電車が動いたらまた電話をするように言ってください。',
        sample: const [
          DialogueLine('T', 'はい。グリーンマートです。'),
          DialogueLine('S', 'もしもし、＿＿と申しますが、店長の＿＿さんはいらっしゃいますか。'),
          DialogueLine('T', 'はい。私ですが。'),
          DialogueLine('S', 'あの、今日＿＿に面接のお約束をしている＿＿です。'),
          DialogueLine('T', 'ああ、留学生の。'),
          DialogueLine(
              'S', 'はい。実は、電車が止まってしまって、＿＿には間に合いそうにないんですが……。'),
          DialogueLine('T', 'ああ、そうですか。'),
          DialogueLine('S',
              '今、駅にいるんですが、さっきの＿＿の影響とかで、いつ動くかわからないんです。'
              'ここからそちらまで行くのに、他の方法がないんですが、どうしたらいいでしょうか。'),
          DialogueLine('T', 'それじゃあ、しかたがないですね。電車が動き次第、また連絡してください。'),
        ],
      ),
    ];
    return [samples[sample % samples.length]];
  }

  /// 3 câu Q&A cho 1 đề — đúng 1 câu mỗi nhóm (① có tranh · ② không tranh ·
  /// ③ tự do), theo chuẩn JPD316. Giảng viên sửa/đổi trong ngân hàng câu hỏi.
  List<QaQuestion> _cloneQuestions(String examId) {
    QaQuestion q(int no, QaGroup g, String lesson, String grammar, String prompt,
            [String? prop]) =>
        QaQuestion(
            id: '${examId}__q$no',
            examId: examId,
            order: no,
            group: g,
            lesson: lesson,
            grammar: grammar,
            prompt: prompt,
            propType: prop);
    return [
      q(1, QaGroup.withImage, '課1', '〜において／〜における',
          '（新聞記事などを見せる）何が書いてありますか。', '新聞記事'),
      q(2, QaGroup.noImage, '課1', '〜でも（極端な例）',
          '私はタイ料理を作ったことがないんですが、私でもできますか。'),
      q(3, QaGroup.free, '課1', '〜がきっかけで',
          'どうして日本語を勉強しようと思ったんですか。'),
    ];
  }
}

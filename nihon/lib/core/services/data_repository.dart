import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../data/models/srs_card.dart';
import '../../features/lessons/kanji_data.dart';
import '../../features/review/review_screen.dart';

class DataRepository {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  final List<LessonData> lessons = [];
  final List<GrammarPoint> grammarPoints = [];
  final List<CardProgress> srsCards = [];

  final ValueNotifier<List<LessonData>> lessonsNotifier = ValueNotifier([]);
  final ValueNotifier<List<GrammarPoint>> grammarPointsNotifier = ValueNotifier([]);
  final ValueNotifier<List<CardProgress>> srsCardsNotifier = ValueNotifier([]);

  int dailyGoal = 50;
  final Map<String, int> dailyXpHistory = {};
  final ValueNotifier<Map<String, int>> xpHistoryNotifier = ValueNotifier({});

  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Populate with default data first (Instant load)
    _loadDefaultData();

    // 2. Listen to authentication state changes to sync with Firestore
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _syncWithFirestore().catchError((e) {
        print("⚠️ Firestore sync failed, using local offline data: $e");
      });
    });
  }

  void _loadDefaultData() {
    lessons.clear();
    lessons.addAll(kLessonsList);
    lessonsNotifier.value = List.from(lessons);

    grammarPoints.clear();
    grammarPoints.addAll(kGrammarPoints);
    grammarPointsNotifier.value = List.from(grammarPoints);

    srsCards.clear();
    final now = DateTime.now();
    // 10 default Kanji review cards
    const sampleSrs = [
      SrsCard(
        word: '水',
        furigana: 'みず',
        romaji: 'THỦY',
        meaning: 'nước',
        category: 'Hán tự — Kanji',
        exampleJa: '水を一杯ください。',
        exampleVi: 'Cho tôi xin một cốc nước.',
      ),
      SrsCard(
        word: '人',
        furigana: 'ひと',
        romaji: 'NHÂN',
        meaning: 'người',
        category: 'Hán tự — Kanji',
        exampleJa: 'あの人は誰ですか。',
        exampleVi: 'Người kia là ai vậy?',
      ),
      SrsCard(
        word: '山',
        furigana: 'やま',
        romaji: 'SƠN',
        meaning: 'núi',
        category: 'Hán tự — Kanji',
        exampleJa: '富士山は高い山です。',
        exampleVi: 'Núi Phú Sĩ là một ngọn núi cao.',
      ),
      SrsCard(
        word: '川',
        furigana: 'かわ',
        romaji: 'XUYÊN',
        meaning: 'sông',
        category: 'Hán tự — Kanji',
        exampleJa: '川で魚を釣ります。',
        exampleVi: 'Tôi câu cá ở sông.',
      ),
      SrsCard(
        word: '日',
        furigana: 'ひ',
        romaji: 'NHẬT',
        meaning: 'ngày, mặt trời',
        category: 'Hán tự — Kanji',
        exampleJa: '今日はいい天気です。',
        exampleVi: 'Hôm nay thời tiết đẹp.',
      ),
      SrsCard(
        word: '本',
        furigana: 'ほん',
        romaji: 'BẢN',
        meaning: 'sách, nguồn gốc',
        category: 'Hán tự — Kanji',
        exampleJa: 'この本は面白いです。',
        exampleVi: 'Cuốn sách này thú vị.',
      ),
      SrsCard(
        word: '月',
        furigana: 'つき',
        romaji: 'NGUYỆT',
        meaning: 'tháng, mặt trăng',
        category: 'Hán tự — Kanji',
        exampleJa: '月が綺麗ですね。',
        exampleVi: 'Trăng đẹp quá nhỉ.',
      ),
      SrsCard(
        word: '木',
        furigana: 'き',
        romaji: 'MỘC',
        meaning: 'cây',
        category: 'Hán tự — Kanji',
        exampleJa: '庭に大きな木があります。',
        exampleVi: 'Trong vườn có một cái cây lớn.',
      ),
      SrsCard(
        word: '火',
        furigana: 'ひ',
        romaji: 'HỎA',
        meaning: 'lửa',
        category: 'Hán tự — Kanji',
        exampleJa: '火をつけないでください。',
        exampleVi: 'Vui lòng không đốt lửa.',
      ),
      SrsCard(
        word: '金',
        furigana: 'かね',
        romaji: 'KIM',
        meaning: 'tiền, vàng',
        category: 'Hán tự — Kanji',
        exampleJa: 'お金がありません。',
        exampleVi: 'Tôi không có tiền.',
      ),
    ];

    for (int i = 0; i < sampleSrs.length; i++) {
      final card = sampleSrs[i];
      final isDue = i < 4;
      String stage = '見習い I';
      if (i >= 5 && i < 8) stage = '弟子 I';

      srsCards.add(CardProgress(
        card: card,
        srsStage: stage,
        nextReview: isDue 
            ? now.subtract(const Duration(minutes: 5)) 
            : now.add(Duration(hours: (i - 3) * 4)),
      ));
    }
    srsCardsNotifier.value = List.from(srsCards);
  }

  Future<void> _syncWithFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    // 1. Sync Lessons
    final lessonsSnap = await _firestore.collection('lessons').get();
    if (lessonsSnap.docs.isEmpty) {
      // Initialize firestore with default data if empty
      for (final l in lessons) {
        await _firestore.collection('lessons').add(_lessonToMap(l));
      }
    } else {
      lessons.clear();
      for (final doc in lessonsSnap.docs) {
        lessons.add(_lessonFromMap(doc.data()));
      }
      lessonsNotifier.value = List.from(lessons);
    }

    // 2. Sync grammar points
    final grammarSnap = await _firestore.collection('grammar_points').get();
    if (grammarSnap.docs.isEmpty) {
      for (final g in grammarPoints) {
        await _firestore.collection('grammar_points').add(_grammarPointToMap(g));
      }
    } else {
      grammarPoints.clear();
      for (final doc in grammarSnap.docs) {
        grammarPoints.add(_grammarPointFromMap(doc.data()));
      }
      grammarPointsNotifier.value = List.from(grammarPoints);
    }

    // 3. Sync SRS Cards (User-specific if logged in)
    if (user != null) {
      final cardsSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('srs_cards')
          .get();
      if (cardsSnap.docs.isEmpty) {
        // Initialize user's firestore cards with default data if empty
        for (final c in srsCards) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('srs_cards')
              .add(_progressToMap(c));
        }
      } else {
        srsCards.clear();
        for (final doc in cardsSnap.docs) {
          srsCards.add(_progressFromMap(doc.data()));
        }
        srsCardsNotifier.value = List.from(srsCards);
      }
    } else {
      _loadDefaultData();
    }

    // 4. Auto-generate SRS cards from all lessons Kanji
    _generateSrsCardsFromLessons();

    // 5. Load XP history from Firestore
    await _loadXpHistoryFromFirestore();
  }

  // Tự động đồng bộ và sinh thẻ ôn tập SRS cho tất cả chữ Hán trong bài học
  void _generateSrsCardsFromLessons() {
    final now = DateTime.now();
    final existingWords = srsCards.map((c) => c.card.word).toSet();
    bool updated = false;

    for (final lesson in lessons) {
      for (final kanji in lesson.kanjis) {
        if (!existingWords.contains(kanji.character)) {
          String exampleJa = '';
          String exampleVi = '';
          if (kanji.examples.isNotEmpty) {
            final parts = kanji.examples.first.split(':');
            exampleJa = parts.first.trim();
            exampleVi = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';
          }

          final card = SrsCard(
            word: kanji.character,
            furigana: kanji.kunyomi.isNotEmpty ? kanji.kunyomi : kanji.onyomi,
            romaji: kanji.hanViet,
            meaning: kanji.meaning,
            category: 'Hán tự — Kanji',
            exampleJa: exampleJa.isNotEmpty ? exampleJa : kanji.character,
            exampleVi: exampleVi.isNotEmpty ? exampleVi : kanji.meaning,
          );

          final progress = CardProgress(
            card: card,
            srsStage: '見習い I',
            nextReview: now,
          );

          srsCards.add(progress);
          existingWords.add(kanji.character);
          updated = true;

          // Lưu lên Firestore
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            _firestore
                .collection('users')
                .doc(user.uid)
                .collection('srs_cards')
                .add(_progressToMap(progress))
                .catchError((e) {
              print("Error auto-adding SRS card: $e");
            });
          }
        }
      }
    }

    if (updated) {
      srsCardsNotifier.value = List.from(srsCards);
    }
  }

  // Notify listeners to trigger rebuilds across dashboard, lessons, review, etc.
  void notifyReviewStateChanged() {
    srsCardsNotifier.value = List.from(srsCards);
    // Push changes to Firestore asynchronously
    for (final c in srsCards) {
      _updateProgressInFirestore(c);
    }
  }

  Future<void> _updateProgressInFirestore(CardProgress progress) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('srs_cards')
            .where('card.word', isEqualTo: progress.card.word)
            .get();
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.update(_progressToMap(progress));
        }
      }
    } catch (e) {
      print("Error updating progress in firestore: $e");
    }
  }

  // ── LESSONS CRUD ──────────────────────────────────────────

  Future<void> addLesson(LessonData lesson) async {
    lessons.add(lesson);
    lessonsNotifier.value = List.from(lessons);
    try {
      await _firestore.collection('lessons').add(_lessonToMap(lesson));
      _generateSrsCardsFromLessons();
    } catch (e) {
      print("Firestore error: $e");
      rethrow;
    }
  }

  Future<void> updateLesson(int index, LessonData lesson, String oldTitle) async {
    if (index >= 0 && index < lessons.length) {
      lessons[index] = lesson;
      lessonsNotifier.value = List.from(lessons);
      try {
        final snap = await _firestore
            .collection('lessons')
            .where('title', isEqualTo: oldTitle)
            .get();
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.set(_lessonToMap(lesson));
        }
        _generateSrsCardsFromLessons();
      } catch (e) {
        print("Firestore error: $e");
        rethrow;
      }
    }
  }

  Future<void> deleteLesson(int index, String title) async {
    if (index >= 0 && index < lessons.length) {
      lessons.removeAt(index);
      lessonsNotifier.value = List.from(lessons);
      try {
        final snap = await _firestore
            .collection('lessons')
            .where('title', isEqualTo: title)
            .get();
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.delete();
        }
      } catch (e) {
        print("Firestore error: $e");
        rethrow;
      }
    }
  }

  Future<void> addGrammarPoint(GrammarPoint grammarPoint) async {
    grammarPoints.add(grammarPoint);
    grammarPointsNotifier.value = List.from(grammarPoints);
    try {
      await _firestore.collection('grammar_points').add(_grammarPointToMap(grammarPoint));
    } catch (e) {
      print("Firestore error: $e");
      rethrow;
    }
  }

  Future<void> updateGrammarPoint(int index, GrammarPoint grammarPoint, String oldTitle) async {
    if (index >= 0 && index < grammarPoints.length) {
      grammarPoints[index] = grammarPoint;
      grammarPointsNotifier.value = List.from(grammarPoints);
      try {
        final snap = await _firestore
            .collection('grammar_points')
            .where('title', isEqualTo: oldTitle)
            .get();
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.set(_grammarPointToMap(grammarPoint));
        }
      } catch (e) {
        print("Firestore error: $e");
        rethrow;
      }
    }
  }

  Future<void> deleteGrammarPoint(int index, String title) async {
    if (index >= 0 && index < grammarPoints.length) {
      grammarPoints.removeAt(index);
      grammarPointsNotifier.value = List.from(grammarPoints);
      try {
        final snap = await _firestore
            .collection('grammar_points')
            .where('title', isEqualTo: title)
            .get();
        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.delete();
        }
      } catch (e) {
        print("Firestore error: $e");
        rethrow;
      }
    }
  }

  // ── SRS CARDS CRUD ────────────────────────────────────────

  Future<void> addSrsCard(SrsCard card) async {
    final progress = CardProgress(
      card: card,
      srsStage: '見習い I',
      nextReview: DateTime.now(),
    );
    srsCards.add(progress);
    srsCardsNotifier.value = List.from(srsCards);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('srs_cards')
            .add(_progressToMap(progress));
      }
    } catch (e) {
      print("Firestore error: $e");
    }
  }

  Future<void> updateSrsCard(int index, SrsCard card, String oldWord) async {
    if (index >= 0 && index < srsCards.length) {
      final updated = CardProgress(
        card: card,
        srsStage: srsCards[index].srsStage,
        nextReview: srsCards[index].nextReview,
      );
      srsCards[index] = updated;
      srsCardsNotifier.value = List.from(srsCards);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final snap = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('srs_cards')
              .where('card.word', isEqualTo: oldWord)
              .get();
          if (snap.docs.isNotEmpty) {
            await snap.docs.first.reference.set(_progressToMap(updated));
          }
        }
      } catch (e) {
        print("Firestore error: $e");
      }
    }
  }

  Future<void> deleteSrsCard(int index, String word) async {
    if (index >= 0 && index < srsCards.length) {
      srsCards.removeAt(index);
      srsCardsNotifier.value = List.from(srsCards);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final snap = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('srs_cards')
              .where('card.word', isEqualTo: word)
              .get();
          if (snap.docs.isNotEmpty) {
            await snap.docs.first.reference.delete();
          }
        }
      } catch (e) {
        print("Firestore error: $e");
      }
    }
  }

  // ── SERIALIZATION HELPERS ─────────────────────────────────

  Map<String, dynamic> _lessonToMap(LessonData l) {
    return {
      'title': l.title,
      'jpTitle': l.jpTitle,
      'description': l.description,
      'kanjis': l.kanjis.map((k) => _kanjiToMap(k)).toList(),
    };
  }

  LessonData _lessonFromMap(Map<String, dynamic> m) {
    final title = m['title'] ?? '';

    return LessonData(
      title: title,
      jpTitle: m['jpTitle'] ?? '',
      description: m['description'] ?? '',
      kanjis: (m['kanjis'] as List? ?? [])
          .map((k) => _kanjiFromMap(Map<String, dynamic>.from(k)))
          .toList(),
    );
  }

  Map<String, dynamic> _grammarPointToMap(GrammarPoint g) {
    return {
      'title': g.title,
      'subTitle': g.subTitle,
      'pattern': g.pattern,
      'note': g.note,
      'examples': g.examples
          .map((e) => {
                'exampleJa': e.exampleJa,
                'exampleVi': e.exampleVi,
              })
          .toList(),
    };
  }

  GrammarPoint _grammarPointFromMap(Map<String, dynamic> m) {
    return GrammarPoint(
      title: m['title'] ?? '',
      subTitle: m['subTitle'] ?? '',
      pattern: m['pattern'] ?? '',
      note: m['note'] ?? '',
      examples: (m['examples'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .map((e) => GrammarExample(
                exampleJa: e['exampleJa'] ?? '',
                exampleVi: e['exampleVi'] ?? '',
              ))
          .toList(),
    );
  }

  Map<String, dynamic> _kanjiToMap(KanjiData k) {
    return {
      'character': k.character,
      'hanViet': k.hanViet,
      'onyomi': k.onyomi,
      'kunyomi': k.kunyomi,
      'meaning': k.meaning,
      'examples': k.examples,
      'strokes': k.strokes.map((s) => _strokeToMap(s)).toList(),
    };
  }

  KanjiData _kanjiFromMap(Map<String, dynamic> m) {
    return KanjiData(
      character: m['character'] ?? '',
      hanViet: m['hanViet'] ?? '',
      onyomi: m['onyomi'] ?? '',
      kunyomi: m['kunyomi'] ?? '',
      meaning: m['meaning'] ?? '',
      examples: List<String>.from(m['examples'] ?? []),
      strokes: (m['strokes'] as List? ?? [])
          .map((s) => _strokeFromMap(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }

  Map<String, dynamic> _strokeToMap(KanjiStroke s) {
    return {
      'points': s.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    };
  }

  KanjiStroke _strokeFromMap(Map<String, dynamic> m) {
    final pts = (m['points'] as List? ?? [])
        .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
        .toList();
    return KanjiStroke(points: pts);
  }

  Map<String, dynamic> _progressToMap(CardProgress p) {
    return {
      'srsStage': p.srsStage,
      'nextReview': p.nextReview.toIso8601String(),
      'card': {
        'word': p.card.word,
        'furigana': p.card.furigana,
        'romaji': p.card.romaji,
        'meaning': p.card.meaning,
        'category': p.card.category,
        'exampleJa': p.card.exampleJa,
        'exampleVi': p.card.exampleVi,
      }
    };
  }

  CardProgress _progressFromMap(Map<String, dynamic> m) {
    final cMap = Map<String, dynamic>.from(m['card'] ?? {});
    return CardProgress(
      card: SrsCard(
        word: cMap['word'] ?? '',
        furigana: cMap['furigana'] ?? '',
        romaji: cMap['romaji'] ?? '',
        meaning: cMap['meaning'] ?? '',
        category: cMap['category'] ?? '',
        exampleJa: cMap['exampleJa'] ?? '',
        exampleVi: cMap['exampleVi'] ?? '',
      ),
      srsStage: m['srsStage'] ?? '見習い I',
      nextReview: DateTime.tryParse(m['nextReview'] ?? '') ?? DateTime.now(),
    );
  }

  // ── XP & PROGRESS HISTORY ──────────────────────────────────

  Future<void> addXp(int amount) async {
    final todayStr = _getTodayKey();
    final currentTodayXp = dailyXpHistory[todayStr] ?? 0;
    dailyXpHistory[todayStr] = currentTodayXp + amount;
    xpHistoryNotifier.value = Map.from(dailyXpHistory);

    // Sync to Firestore
    await _saveXpHistoryToFirestore();
  }

  int get streak {
    if (dailyXpHistory.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    final todayStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
    bool hasToday = (dailyXpHistory[todayStr] ?? 0) > 0;

    if (!hasToday) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final dateStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      if ((dailyXpHistory[dateStr] ?? 0) > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _saveXpHistoryToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('user_stats').doc(user.uid).set({
          'dailyGoal': dailyGoal,
          'dailyXpHistory': dailyXpHistory,
        });
      }
    } catch (e) {
      print("Error saving XP history: $e");
    }
  }

  Future<void> _loadXpHistoryFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('user_stats').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            dailyGoal = data['dailyGoal'] as int? ?? 50;
            final historyMap = data['dailyXpHistory'] as Map<String, dynamic>? ?? {};
            dailyXpHistory.clear();
            historyMap.forEach((key, value) {
              dailyXpHistory[key] = (value as num).toInt();
            });
            xpHistoryNotifier.value = Map.from(dailyXpHistory);
          }
        }
      }
    } catch (e) {
      print("Error loading XP history: $e");
    }
  }
}

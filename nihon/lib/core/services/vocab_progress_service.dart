import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/srs_stage.dart';
import 'role_service.dart';

/// Trạng thái một phiên ôn từ vựng đã lưu (để vào lại học tiếp từ chỗ cũ).
class VocabSessionState {
  final List<String> order; // thứ tự các doc id đã xáo
  final int index; // đang học đến thẻ thứ mấy
  final int xp; // XP tích trong phiên
  final int total;
  final bool done;

  const VocabSessionState({
    required this.order,
    required this.index,
    required this.xp,
    required this.total,
    required this.done,
  });
}

/// Lưu / đọc tiến trình học từ vựng của user hiện tại trên Firestore:
/// - `users/{uid}/vocab_progress/{vocabId}` — cấp SRS từng thẻ.
/// - `users/{uid}/vocab_sessions/{book_lesson}` — học đến đâu trong bài.
/// Guest (chưa đăng nhập): mọi hàm no-op / trả rỗng, phiên chỉ chạy trong RAM.
class VocabProgressService {
  static final VocabProgressService _instance =
      VocabProgressService._internal();
  factory VocabProgressService() => _instance;
  VocabProgressService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  /// User được phép lưu tiến trình: phải đăng nhập THẬT.
  /// Guest và tài khoản ẩn danh (module Luyện nghe tự signInAnonymously nên
  /// máy của guest vẫn có currentUser) đều KHÔNG lưu.
  User? get _user {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) return null;
    if (RoleService().currentRole.value == AppRole.guest) return null;
    return u;
  }

  String sessionKey(String book, int lesson) => '${book}_$lesson';

  CollectionReference<Map<String, dynamic>> _progressCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('vocab_progress');

  CollectionReference<Map<String, dynamic>> _sessionsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('vocab_sessions');

  /// Cấp SRS đã lưu của các thẻ trong một bài: vocabId -> SrsStage.
  Future<Map<String, SrsStage>> loadCardStages(String book, int lesson) async {
    final user = _user;
    if (user == null) return {};
    try {
      final snap = await _progressCol(user.uid)
          .where('book', isEqualTo: book)
          .where('lesson', isEqualTo: lesson)
          .get();
      final result = <String, SrsStage>{};
      for (final doc in snap.docs) {
        final stageName = doc.data()['stage'] as String?;
        result[doc.id] = SrsStage.values.firstWhere(
          (s) => s.name == stageName,
          orElse: () => SrsStage.apprentice1,
        );
      }
      return result;
    } catch (e) {
      debugPrint('VocabProgress: lỗi tải cấp SRS: $e');
      return {};
    }
  }

  /// Ghi kết quả một lần trả lời thẻ (đúng / sai) + cấp SRS mới.
  Future<void> saveCardResult({
    required String vocabId,
    required String book,
    required int lesson,
    required SrsStage stage,
    required bool correct,
  }) async {
    final user = _user;
    if (user == null) return;
    try {
      await _progressCol(user.uid).doc(vocabId).set({
        'book': book,
        'lesson': lesson,
        'stage': stage.name,
        'nextReview': Timestamp.fromDate(_nextReviewFor(stage)),
        if (correct)
          'correctCount': FieldValue.increment(1)
        else
          'wrongCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('VocabProgress: lỗi lưu kết quả thẻ: $e');
    }
  }

  /// Phiên ôn dang dở (nếu có) của một bài.
  Future<VocabSessionState?> loadSession(String book, int lesson) async {
    final user = _user;
    if (user == null) return null;
    try {
      final doc =
          await _sessionsCol(user.uid).doc(sessionKey(book, lesson)).get();
      final data = doc.data();
      if (data == null) return null;
      return VocabSessionState(
        order: List<String>.from(data['order'] as List? ?? const []),
        index: (data['index'] as num?)?.toInt() ?? 0,
        xp: (data['xp'] as num?)?.toInt() ?? 0,
        total: (data['total'] as num?)?.toInt() ?? 0,
        done: data['done'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('VocabProgress: lỗi tải phiên: $e');
      return null;
    }
  }

  /// Lưu vị trí hiện tại của phiên (gọi sau mỗi lần trả lời / bắt đầu phiên).
  Future<void> saveSession({
    required String book,
    required int lesson,
    required List<String> order,
    required int index,
    required int xp,
  }) async {
    final user = _user;
    if (user == null) return;
    try {
      await _sessionsCol(user.uid).doc(sessionKey(book, lesson)).set({
        'book': book,
        'lesson': lesson,
        'order': order,
        'index': index,
        'xp': xp,
        'total': order.length,
        'done': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('VocabProgress: lỗi lưu phiên: $e');
    }
  }

  /// Đánh dấu đã ôn hết bài.
  Future<void> completeSession({
    required String book,
    required int lesson,
    required int total,
    required int xp,
  }) async {
    final user = _user;
    if (user == null) return;
    try {
      await _sessionsCol(user.uid).doc(sessionKey(book, lesson)).set({
        'book': book,
        'lesson': lesson,
        'order': FieldValue.delete(),
        'index': total,
        'xp': xp,
        'total': total,
        'done': true,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('VocabProgress: lỗi đánh dấu hoàn thành: $e');
    }
  }

  /// Tiến trình mọi bài của một giáo trình: lesson -> trạng thái phiên.
  Future<Map<int, VocabSessionState>> loadBookProgress(String book) async {
    final user = _user;
    if (user == null) return {};
    try {
      final snap =
          await _sessionsCol(user.uid).where('book', isEqualTo: book).get();
      final result = <int, VocabSessionState>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final lesson = (data['lesson'] as num?)?.toInt();
        if (lesson == null) continue;
        result[lesson] = VocabSessionState(
          order: List<String>.from(data['order'] as List? ?? const []),
          index: (data['index'] as num?)?.toInt() ?? 0,
          xp: (data['xp'] as num?)?.toInt() ?? 0,
          total: (data['total'] as num?)?.toInt() ?? 0,
          done: data['done'] as bool? ?? false,
        );
      }
      return result;
    } catch (e) {
      debugPrint('VocabProgress: lỗi tải tiến trình giáo trình: $e');
      return {};
    }
  }

  /// Hạn ôn lại tiếp theo tương ứng cấp SRS (lưu sẵn cho tính năng "đến hạn").
  DateTime _nextReviewFor(SrsStage stage) {
    final now = DateTime.now();
    switch (stage) {
      case SrsStage.apprentice1:
        return now.add(const Duration(hours: 4));
      case SrsStage.apprentice2:
        return now.add(const Duration(hours: 8));
      case SrsStage.apprentice3:
        return now.add(const Duration(days: 1));
      case SrsStage.apprentice4:
        return now.add(const Duration(days: 2));
      case SrsStage.guru1:
        return now.add(const Duration(days: 7));
      case SrsStage.guru2:
        return now.add(const Duration(days: 14));
      case SrsStage.master:
        return now.add(const Duration(days: 30));
      case SrsStage.enlightened:
        return now.add(const Duration(days: 120));
      case SrsStage.burned:
        return now.add(const Duration(days: 3650));
    }
  }
}

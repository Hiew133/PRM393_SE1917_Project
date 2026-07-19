import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import 'ai_conversation_service.dart';

/// Một buổi luyện nói đã lưu trong lịch sử.
class SpeakingSessionRecord {
  final String id;
  final String mode; // 'free' | 'jpd316' | 'nihon1' | 'nihon2'
  final String title; // tên tình huống / đề
  final DateTime createdAt;
  final int? score; // điểm tổng (phân tích hoặc tổng điểm thi)
  final SessionAnalysis? analysis; // null với buổi thi Nhật 1/2
  final List<int?> examScores; // điểm từng lượt (chỉ buổi thi)
  final List<ChatMessage> transcript;

  const SpeakingSessionRecord({
    required this.id,
    required this.mode,
    required this.title,
    required this.createdAt,
    required this.score,
    required this.analysis,
    required this.examScores,
    required this.transcript,
  });

  String get modeLabel {
    switch (mode) {
      case 'nihon1':
        return 'Thi Nhật 1';
      case 'nihon2':
        return 'Thi Nhật 2';
      case 'jpd316':
        return 'Thi Nhật 3';
      default:
        return 'Tự do';
    }
  }
}

/// Lưu / đọc lịch sử các buổi luyện nói của user hiện tại trên Firestore:
/// `users/{uid}/speaking_sessions/{auto-id}`.
///
/// Mọi hàm đều tự nuốt lỗi (guest / chưa đăng nhập / Firebase chưa init trong
/// test → bỏ qua) để không bao giờ làm hỏng buổi luyện đang chạy.
class SpeakingHistoryService {
  static User? get _user {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) return null;
    return u;
  }

  static CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default')
          .collection('users')
          .doc(uid)
          .collection('speaking_sessions');

  /// Lưu một buổi luyện vừa kết thúc. Fire-and-forget.
  static Future<void> saveSession({
    required String mode,
    required String title,
    required List<ChatMessage> transcript,
    int? score,
    SessionAnalysis? analysis,
    List<int?> examScores = const [],
  }) async {
    try {
      final user = _user;
      if (user == null) return;
      await _col(user.uid).add({
        'mode': mode,
        'title': title,
        'score': score,
        'createdAt': FieldValue.serverTimestamp(),
        'transcript': [
          for (final m in transcript)
            if (!m.isPending && m.japanese.isNotEmpty)
              {
                'fromUser': m.fromUser,
                'japanese': m.japanese,
                if (m.reading != null) 'reading': m.reading,
                if (m.translation != null) 'translation': m.translation,
                if (m.pronunciationScore != null)
                  'pronunciationScore': m.pronunciationScore,
              },
        ],
        if (analysis != null)
          'analysis': {
            'overallScore': analysis.overallScore,
            'summary': analysis.summary,
            'strengths': analysis.strengths,
            'improvements': analysis.improvements,
            'sentenceNotes': [
              for (final n in analysis.sentenceNotes)
                {
                  'original': n.original,
                  'issue': n.issue,
                  'better': n.better,
                  'betterReading': n.betterReading,
                },
            ],
            'farewellJp': analysis.farewellJp,
          },
        if (examScores.isNotEmpty) 'examScores': examScores,
      });
    } catch (e) {
      debugPrint('SpeakingHistory: lỗi lưu buổi luyện: $e');
    }
  }

  /// Danh sách buổi luyện gần nhất (mới → cũ).
  static Future<List<SpeakingSessionRecord>> listSessions(
      {int limit = 50}) async {
    try {
      final user = _user;
      if (user == null) return [];
      final snap = await _col(user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return [for (final doc in snap.docs) _fromDoc(doc)];
    } catch (e) {
      debugPrint('SpeakingHistory: lỗi tải lịch sử: $e');
      return [];
    }
  }

  static SpeakingSessionRecord _fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final analysisMap = data['analysis'] as Map<String, dynamic>?;
    return SpeakingSessionRecord(
      id: doc.id,
      mode: data['mode'] as String? ?? 'free',
      title: data['title'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      score: (data['score'] as num?)?.toInt(),
      analysis: analysisMap == null
          ? null
          : SessionAnalysis(
              overallScore: (analysisMap['overallScore'] as num?)?.toInt() ?? 0,
              summary: analysisMap['summary'] as String? ?? '',
              strengths: List<String>.from(
                  analysisMap['strengths'] as List? ?? const []),
              improvements: List<String>.from(
                  analysisMap['improvements'] as List? ?? const []),
              sentenceNotes: [
                for (final n
                    in (analysisMap['sentenceNotes'] as List? ?? const []))
                  SentenceNote(
                    original: (n as Map)['original'] as String? ?? '',
                    issue: n['issue'] as String? ?? '',
                    better: n['better'] as String? ?? '',
                    betterReading: n['betterReading'] as String? ?? '',
                  ),
              ],
              farewellJp: analysisMap['farewellJp'] as String? ?? '',
            ),
      examScores: [
        for (final s in (data['examScores'] as List? ?? const []))
          (s as num?)?.toInt(),
      ],
      transcript: [
        for (final m in (data['transcript'] as List? ?? const []))
          ChatMessage(
            fromUser: (m as Map)['fromUser'] as bool? ?? false,
            japanese: m['japanese'] as String? ?? '',
            reading: m['reading'] as String?,
            translation: m['translation'] as String?,
            pronunciationScore: (m['pronunciationScore'] as num?)?.toInt(),
          ),
      ],
    );
  }
}

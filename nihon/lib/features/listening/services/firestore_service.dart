import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreService {
  static final FirebaseFirestore _db =
  FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'default',
  );

  static Future<DocumentReference<Map<String, dynamic>>>
  _userListeningDoc() async {
    await AuthService.ensureLoggedIn();

    return _db
        .collection('listening')
        .doc(AuthService.userId);
  }

  static Future<void> saveFavorites(
      List<String> favorites) async {
    final doc = await _userListeningDoc();

    await doc.set({
      'favorites': favorites,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<List<String>> getFavorites() async {
    final doc = await _userListeningDoc();
    final snapshot = await doc.get();

    final data = snapshot.data();

    if (data == null || data['favorites'] == null) {
      return [];
    }

    return List<String>.from(data['favorites']);
  }

  static Future<void> saveCompleted(
      List<String> completed) async {
    final doc = await _userListeningDoc();

    await doc.set({
      'completed': completed,
      'progress': completed.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<List<String>> getCompleted() async {
    final doc = await _userListeningDoc();
    final snapshot = await doc.get();

    final data = snapshot.data();

    if (data == null || data['completed'] == null) {
      return [];
    }

    return List<String>.from(data['completed']);
  }
}
import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_service.dart';

class CompletedService {
  static const String key = "completed_lessons";

  static Future<void> saveCompleted(List<String> completed) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(key, completed);

    try {
      await FirestoreService.saveCompleted(completed);
    } catch (e) {
      // If Firestore save fails, local data is still preserved.
    }
  }

  static Future<List<String>> getCompleted() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final cloudCompleted = await FirestoreService.getCompleted();

      // Luôn lấy Firestore làm chuẩn
      await prefs.setStringList(key, cloudCompleted);

      return cloudCompleted;
    } catch (e) {
      // If Firestore is unavailable, use local data.
    }

    return prefs.getStringList(key) ?? [];
  }
}

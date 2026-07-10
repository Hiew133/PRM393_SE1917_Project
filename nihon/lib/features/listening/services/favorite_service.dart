import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_service.dart';

class FavoriteService {
  static const String favoriteKey = "favorite_lessons";

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final cloudFavorites =
      await FirestoreService.getFavorites();

      if (cloudFavorites.isNotEmpty) {
        await prefs.setStringList(
          favoriteKey,
          cloudFavorites,
        );

        return cloudFavorites;
      }
    } catch (e) {
      // If Firestore is unavailable, use local data.
    }
    return prefs.getStringList(favoriteKey) ?? [];
  }

  static Future<void> saveFavorites(
      List<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      favoriteKey,
      favorites,
    );

    try {
      await FirestoreService.saveFavorites(favorites);
    } catch (e) {
      // If Firestore save fails, local data is still preserved.
    }
  }
}
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<User?> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  static Future<void> ensureLoggedIn() async {
    if (_auth.currentUser == null) {
      await signInAnonymously();
    }
  }

  static String get userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User is not logged in");
    }

    return user.uid;
  }
}
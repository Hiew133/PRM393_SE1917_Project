import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Đăng nhập / liên kết tài khoản Google — KHÔNG cần package google_sign_in.
///
/// Dùng luồng federated có sẵn của firebase_auth:
///  - Web: popup (`signInWithPopup` / `linkWithPopup`).
///  - Android/iOS: provider flow native (`signInWithProvider` / `linkWithProvider`).
///
/// ⚠️ Cần bật **Google** trong Firebase Console → Authentication → Sign-in
/// method. Trên Android bản release còn cần thêm SHA-1/SHA-256 của app.
class GoogleAuthService {
  GoogleAuthService._();

  static GoogleAuthProvider _provider() {
    final provider = GoogleAuthProvider();
    // Luôn cho chọn tài khoản (không tự đăng nhập lại account cũ trên web).
    provider.setCustomParameters({'prompt': 'select_account'});
    return provider;
  }

  /// Đăng nhập bằng Google. Trả về [UserCredential] khi thành công.
  /// Ném [FirebaseAuthException] để caller hiển thị thông báo phù hợp.
  static Future<UserCredential> signIn() {
    if (kIsWeb) {
      return FirebaseAuth.instance.signInWithPopup(_provider());
    }
    return FirebaseAuth.instance.signInWithProvider(_provider());
  }

  /// Liên kết Google vào tài khoản đang đăng nhập (vd tài khoản email/mật
  /// khẩu muốn thêm đăng nhập Google). Ném lỗi nếu chưa đăng nhập.
  static Future<UserCredential> linkToCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Bạn cần đăng nhập trước khi liên kết Google.',
      );
    }
    if (kIsWeb) {
      return user.linkWithPopup(_provider());
    }
    return user.linkWithProvider(_provider());
  }

  /// Tài khoản hiện tại đã liên kết Google chưa.
  static bool isGoogleLinked() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  /// Dịch mã lỗi Firebase sang tiếng Việt cho luồng Google.
  static String messageForError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
        case 'user-cancelled':
        case 'web-context-canceled':
          return 'Bạn đã hủy đăng nhập Google.';
        case 'popup-blocked':
          return 'Trình duyệt chặn popup. Hãy cho phép popup rồi thử lại.';
        case 'account-exists-with-different-credential':
          return 'Email này đã đăng ký bằng cách khác. Hãy đăng nhập bằng '
              'mật khẩu trước rồi liên kết Google trong Trang cá nhân.';
        case 'credential-already-in-use':
          return 'Tài khoản Google này đã liên kết với người dùng khác.';
        case 'provider-already-linked':
          return 'Tài khoản đã liên kết Google rồi.';
        case 'operation-not-allowed':
          return 'Firebase chưa bật đăng nhập Google. Vào Authentication → '
              'Sign-in method để bật Google.';
        case 'network-request-failed':
          return 'Không kết nối được. Kiểm tra mạng rồi thử lại.';
        default:
          return error.message ?? 'Không đăng nhập được bằng Google (${error.code}).';
      }
    }
    return 'Không đăng nhập được bằng Google.';
  }
}

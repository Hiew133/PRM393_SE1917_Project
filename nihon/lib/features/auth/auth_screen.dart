import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/google_auth_service.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../admin/admin_home_screen.dart';
import '../home/main_navigation.dart';

class AuthScreen extends StatefulWidget {
  final bool startRegister;

  const AuthScreen({super.key, this.startRegister = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.startRegister;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }



  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Nhập email và mật khẩu trước nhé.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Email chua dung dinh dang.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Mat khau can it nhat 6 ky tu.');
      return;
    }
    if (email.isEmpty && (!email.contains('@') || !email.contains('.'))) {
      setState(() => _error = 'Email chÆ°a Ä‘Ãºng Ä‘á»‹nh dáº¡ng.');
      return;
    }
    if (password.isEmpty && password.length < 6) {
      setState(() => _error = 'Máº­t kháº©u cáº§n Ã­t nháº¥t 6 kÃ½ tá»±.');
      return;
    }
    if (_isRegister && password != confirmPassword) {
      setState(() => _error = 'Mật khẩu xác nhận chưa khớp.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      UserCredential credential;
      AppRole role;
      if (_isRegister) {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 15));
        role = await RoleService().createCustomerProfile(credential.user!).timeout(const Duration(seconds: 8));
      } else {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 15));
        role = await RoleService().loadRoleForUser(credential.user!).timeout(const Duration(seconds: 8));
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => role.canManageContent
              ? const AdminHomeScreen()
              : const MainNavigation(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageForAuthError(e));
    } on TimeoutException {
      setState(() => _error = 'Kết nối Firebase quá lâu. Kiểm tra mạng, Firebase config hoặc Firestore rules rồi thử lại.');
    } catch (e) {
      setState(() => _error = 'Không đăng nhập được. Chi tiết: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final credential = await GoogleAuthService.signIn()
          .timeout(const Duration(seconds: 60));
      final user = credential.user!;
      // Tài khoản Google mới thì tạo hồ sơ, đã có thì nạp quyền.
      final isNew = credential.additionalUserInfo?.isNewUser ?? false;
      final role = isNew
          ? await RoleService().createCustomerProfile(user).timeout(const Duration(seconds: 8))
          : await RoleService().loadRoleForUser(user).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => role.canManageContent
              ? const AdminHomeScreen()
              : const MainNavigation(),
        ),
        (route) => false,
      );
    } on TimeoutException {
      setState(() => _error = 'Kết nối Google/Firebase quá lâu. Thử lại nhé.');
    } catch (e) {
      setState(() => _error = GoogleAuthService.messageForError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Nhập email của bạn ở ô trên rồi bấm "Quên mật khẩu" nhé.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã gửi email đặt lại mật khẩu tới $email. Kiểm tra hộp thư (cả mục Spam).'),
          backgroundColor: AppColors.brandDark,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageForAuthError(e));
    } on TimeoutException {
      setState(() => _error = 'Gửi email quá lâu. Kiểm tra mạng rồi thử lại.');
    } catch (e) {
      setState(() => _error = 'Không gửi được email đặt lại mật khẩu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageForAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email này đã có tài khoản. Hãy chuyển sang Đăng nhập.';
      case 'invalid-email':
        return 'Email chưa đúng định dạng.';
      case 'weak-password':
        return 'Mật khẩu nên có ít nhất 6 ký tự.';
      case 'operation-not-allowed':
        return 'Firebase chưa bật đăng nhập Email/Password. Vào Firebase Authentication > Sign-in method và bật Email/Password.';
      case 'network-request-failed':
        return 'Không kết nối được Firebase. Kiểm tra mạng rồi thử lại.';
      case 'too-many-requests':
        return 'Bạn thử quá nhiều lần. Chờ một chút rồi thử lại.';
      case 'user-disabled':
        return 'Tài khoản này đã bị khóa.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu chưa đúng.';
      default:
        final detail = e.message;
        if (detail == null || detail.trim().isEmpty || detail.trim().toLowerCase() == 'error') {
          return 'Firebase báo lỗi ${e.code}. Kiểm tra Firebase Authentication và cấu hình project.';
        }
        return detail;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isRegister ? 'Đăng ký' : 'Đăng nhập',
          style: AppTextStyles.latin(size: 20, weight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRegister ? 'Tạo tài khoản mới' : 'Chào mừng quay lại',
                  style: AppTextStyles.latin(size: 18, weight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                _AuthField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _AuthField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 12),
                  _AuthField(
                    controller: _confirmPasswordController,
                    label: 'Nhập lại mật khẩu',
                    icon: Icons.lock_reset,
                    obscureText: true,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.vocab.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.vocab.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.vocab, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTextStyles.latin(size: 12, color: AppColors.vocab, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!_isRegister) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Quên mật khẩu?',
                        style: AppTextStyles.latin(size: 13, color: AppColors.brandDark, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: Text(_isLoading ? 'Đang xử lý...' : (_isRegister ? 'Đăng ký' : 'Đăng nhập')),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'hoặc',
                        style: AppTextStyles.latin(size: 12, color: AppColors.textFaint, weight: FontWeight.w600),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const _GoogleGlyph(),
                  label: Text(
                    'Tiếp tục với Google',
                    style: AppTextStyles.latin(size: 15, weight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isRegister = !_isRegister;
                              _error = null;
                            });
                          },
                    child: Text(
                      _isRegister ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Đăng ký',
                      style: AppTextStyles.latin(size: 13, color: AppColors.brandDark, weight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chữ "G" 4 màu của Google (vẽ bằng shader để khỏi bundle asset ảnh).
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFF4285F4), // xanh dương
          Color(0xFFEA4335), // đỏ
          Color(0xFFFBBC05), // vàng
          Color(0xFF34A853), // xanh lá
        ],
        stops: [0.0, 0.4, 0.7, 1.0],
      ).createShader(bounds),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

class _AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}



class _AuthFieldState extends State<_AuthField> {
  late bool _hideText;

  @override
  void initState() {
    super.initState();
    _hideText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _hideText,
      decoration: InputDecoration(
        prefixIcon: Icon(widget.icon, color: AppColors.textFaint),
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _hideText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                icon: Icon(
                  _hideText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textFaint,
                ),
                onPressed: () => setState(() => _hideText = !_hideText),
              )
            : null,
        labelText: widget.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: AppColors.surfaceAlt,
      ),
    );
  }
}

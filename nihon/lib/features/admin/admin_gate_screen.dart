import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'screens/admin_home_screen.dart';

/// Mã PIN vào trang Giảng viên (Admin).
///
/// Mặc định `2024`, đổi khi build:
/// `--dart-define=ADMIN_PIN=1357`
class AdminAuth {
  AdminAuth._();
  static const String pin =
      String.fromEnvironment('ADMIN_PIN', defaultValue: '2024');
}

/// Cổng nhập PIN trước khi vào khu vực Admin (chấm/soạn đề).
class AdminGateScreen extends StatefulWidget {
  const AdminGateScreen({super.key});

  @override
  State<AdminGateScreen> createState() => _AdminGateScreenState();
}

class _AdminGateScreenState extends State<AdminGateScreen> {
  String _entered = '';
  bool _error = false;
  int get _len => AdminAuth.pin.length;

  void _tap(String d) {
    if (_entered.length >= _len) return;
    setState(() {
      _entered += d;
      _error = false;
    });
    if (_entered.length == _len) _verify();
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _verify() {
    if (_entered == AdminAuth.pin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = true;
        _entered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.chevron_left,
                        color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: const Icon(Icons.lock_outline,
                  color: Color(0xFFF7C547), size: 30),
            ),
            const SizedBox(height: 18),
            Text('Trang Giảng viên',
                style: AppTextStyles.latin(size: 20, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                _error
                    ? 'Sai mã PIN, thử lại'
                    : 'Nhập mã PIN để vào khu vực chấm / soạn đề',
                style: AppTextStyles.latin(
                    size: 13,
                    color: _error ? AppColors.vocab : AppColors.textMuted)),
            const SizedBox(height: 26),
            _dots(),
            const Spacer(),
            _keypad(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _len; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _entered.length
                  ? (_error ? AppColors.vocab : AppColors.kanji)
                  : AppColors.border,
            ),
          ),
      ],
    );
  }

  Widget _keypad() {
    Widget key(String label, {VoidCallback? onTap, Widget? child}) {
      return GestureDetector(
        onTap: onTap ?? () => _tap(label),
        child: Container(
          width: 74,
          height: 74,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: child ??
              Text(label,
                  style: AppTextStyles.latin(
                      size: 26, weight: FontWeight.w700)),
        ),
      );
    }

    Widget row(List<Widget> ws) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < ws.length; i++) ...[
                ws[i],
                if (i != ws.length - 1) const SizedBox(width: 18),
              ],
            ],
          ),
        );

    return Column(
      children: [
        row([key('1'), key('2'), key('3')]),
        row([key('4'), key('5'), key('6')]),
        row([key('7'), key('8'), key('9')]),
        row([
          SizedBox(width: 74, height: 74, child: const SizedBox.shrink()),
          key('0'),
          key('',
              onTap: _backspace,
              child: const Icon(Icons.backspace_outlined,
                  color: AppColors.textSecondary)),
        ]),
      ],
    );
  }
}

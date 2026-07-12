import 'package:flutter/material.dart';

import '../../features/auth/auth_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Hộp thoại chung báo "chế độ Khách bị giới hạn" + nút chuyển sang đăng nhập.
///
/// Quy ước gating: mỗi tính năng chỉ mở 1 nội dung dùng thử cho Khách
/// (1 bài Kanji, 1 mẫu ngữ pháp, 1 bài từ vựng, 1 bài nghe, 1 đề Nói Nhật 1);
/// phần còn lại gọi dialog này.
void showGuestLockDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.vocab, size: 28),
          const SizedBox(width: 10),
          Text(
            'Tính năng giới hạn',
            style: AppTextStyles.latin(size: 18, weight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        'Bạn đang sử dụng chế độ Khách. Vui lòng đăng ký hoặc đăng nhập tài khoản để học đầy đủ tất cả các bài học và lưu tiến trình học tập!',
        style: AppTextStyles.latin(size: 14, color: AppColors.textSecondary, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Để sau',
            style: AppTextStyles.latin(size: 14, color: AppColors.textMuted, weight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen(startRegister: false)),
            );
          },
          child: const Text('Đăng nhập ngay'),
        ),
      ],
    ),
  );
}

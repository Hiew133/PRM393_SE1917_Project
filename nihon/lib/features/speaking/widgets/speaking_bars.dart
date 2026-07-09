import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Các thanh/banner nhỏ của màn Luyện nói — chỉ nhận dữ liệu + callback.

/// Thanh thay cho mic khi đã kết thúc buổi luyện (chế độ Tự do / JPD316).
class SessionEndedBar extends StatelessWidget {
  final VoidCallback onRestart;
  const SessionEndedBar({super.key, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, color: AppColors.speaking, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Đã kết thúc buổi luyện.',
                style: AppTextStyles.latin(size: 13, weight: FontWeight.w600)),
          ),
          TextButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Luyện lại'),
            style: TextButton.styleFrom(foregroundColor: AppColors.speaking),
          ),
        ],
      ),
    );
  }
}

/// Thanh thay cho mic khi đã thi xong (chế độ thi Nhật 1).
class ExamDoneBar extends StatelessWidget {
  final VoidCallback onBack;
  const ExamDoneBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.speaking, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Đã hoàn thành phần thi.',
                style: AppTextStyles.latin(
                    size: 13, weight: FontWeight.w600)),
          ),
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Bốc đề khác'),
            style: TextButton.styleFrom(foregroundColor: AppColors.speaking),
          ),
        ],
      ),
    );
  }
}

/// Banner "đang luyện theo đề" (chế độ thi Nhật 3 / JPD316).
class ActiveExamBanner extends StatelessWidget {
  final String jpLabel;
  final String viLabel;
  const ActiveExamBanner(
      {super.key, required this.jpLabel, required this.viLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('🎓', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Đang luyện theo đề · $jpLabel — $viLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.latin(
                  size: 11,
                  weight: FontWeight.w600,
                  color: const Color(0xFF7B3FA8)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner lỗi (đỏ) — cuộn được bên trong để lỗi dài không làm tràn layout.
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 120),
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: Text(
          message,
          style: AppTextStyles.latin(size: 12, color: AppColors.vocab),
        ),
      ),
    );
  }
}

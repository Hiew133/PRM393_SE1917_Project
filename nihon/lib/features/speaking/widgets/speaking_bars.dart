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

/// Thanh thay cho mic khi đã thi xong (chế độ thi Nhật 1 / Nhật 2).
/// [onAnalyze]: nhờ AI phân tích & góp ý cả bài thi (null = ẩn nút — đã
/// phân tích rồi); [analyzing]: đang chờ AI, nút hiện spinner.
class ExamDoneBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onAnalyze;
  final bool analyzing;
  const ExamDoneBar({
    super.key,
    required this.onBack,
    this.onAnalyze,
    this.analyzing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.speaking, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đã hoàn thành phần thi.',
                    style:
                        AppTextStyles.latin(size: 13, weight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Bốc đề khác'),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.speaking),
              ),
            ],
          ),
          if (onAnalyze != null || analyzing) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: analyzing ? null : onAnalyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.speaking,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: analyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.insights_rounded, size: 18),
                label: Text(
                  analyzing
                      ? 'Đang phân tích bài thi…'
                      : 'Xem phân tích & góp ý chi tiết',
                  style:
                      AppTextStyles.latin(size: 13.5, weight: FontWeight.w700),
                ),
              ),
            ),
          ],
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

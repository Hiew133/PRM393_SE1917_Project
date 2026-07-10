import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/chat_message.dart';

/// Bong bóng hội thoại: AI (trái) hoặc người học (phải).
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onListen; // bấm "▶ Nghe" (chỉ với AI)

  const ChatBubble({super.key, required this.message, this.onListen});

  @override
  Widget build(BuildContext context) {
    return message.fromUser ? _userBubble() : _aiBubble();
  }

  // ── AI ────────────────────────────────────────────────
  Widget _aiBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AiAvatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '田中先生 · AI会話',
                style: AppTextStyles.latin(
                  size: 10,
                  weight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: message.isPending
                    ? _typingDots()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.reading != null &&
                              message.reading!.isNotEmpty)
                            Text(
                              message.reading!,
                              style: AppTextStyles.jp(
                                size: 11,
                                weight: FontWeight.w400,
                                color: AppColors.textMuted,
                              ),
                            ),
                          Text(
                            message.japanese,
                            style: AppTextStyles.jp(
                              size: 15,
                              weight: FontWeight.w500,
                              height: 1.6,
                            ),
                          ),
                          if (message.translation != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              message.translation!,
                              style: AppTextStyles.latin(
                                size: 11,
                                color: AppColors.textMuted,
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                          if (message.feedback != null &&
                              message.feedback!.isNotEmpty)
                            _feedbackBox(message.feedback!),
                        ],
                      ),
              ),
              if (!message.isPending && onListen != null) ...[
                const SizedBox(height: 6),
                _listenButton(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _feedbackBox(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 NHẬN XÉT PHÁT ÂM',
            style: AppTextStyles.latin(
              size: 10,
              weight: FontWeight.w700,
              color: AppColors.speaking,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: AppTextStyles.latin(size: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _listenButton() {
    return GestureDetector(
      onTap: onListen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '▶ Nghe',
          style: AppTextStyles.latin(
            size: 11,
            weight: FontWeight.w600,
            color: AppColors.reading,
          ),
        ),
      ),
    );
  }

  Widget _typingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.speaking),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Đang soạn...',
          style: AppTextStyles.latin(size: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ── Người học ─────────────────────────────────────────
  Widget _userBubble() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.speaking,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(
            message.japanese,
            style: AppTextStyles.jp(
              size: 15,
              weight: FontWeight.w500,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
        if (message.pronunciationScore != null) ...[
          const SizedBox(height: 6),
          _scoreBadge(message.pronunciationScore!),
        ],
      ],
    );
  }

  Widget _scoreBadge(int score) {
    final ok = score >= 70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
        border: Border.all(
          color: ok ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '発音 $score%',
            style: AppTextStyles.latin(
              size: 10,
              weight: FontWeight.w700,
              color: ok ? AppColors.speaking : AppColors.listening,
            ),
          ),
          const SizedBox(width: 4),
          Text(ok ? '✓' : '·', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.speaking, AppColors.reading],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'AI',
        style: AppTextStyles.jp(
          size: 12,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

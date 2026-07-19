import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Thanh nhập bằng giọng nói. Có 3 trạng thái:
/// 1. **Chờ**: ô gợi ý + nút mic (bấm để bắt đầu nói).
/// 2. **Đang nghe**: hiện chữ nhận diện live + nút dừng đỏ.
/// 3. **Xem lại (draft)**: sau khi bấm dừng, câu KHÔNG gửi ngay — hiện lại cho
///    người dùng đọc (KHÔNG sửa tay được): sai thì 🗑 xóa nói lại, thiếu thì
///    🎙 nói thêm, ưng rồi bấm ➤ gửi.
///
/// [voiceMode] (hội thoại Tự do / JPD316): KHÔNG hiện chữ — chỉ có nút mic
/// như một cuộc gọi thoại; bấm dừng là câu được gửi luôn. (Draft chỉ còn xuất
/// hiện khi lượt gửi bị lỗi — để bấm ➤ gửi lại mà không phải nói lại.)
class VoiceInputBar extends StatelessWidget {
  final bool listening;
  final bool busy;
  final bool voiceMode;
  final String partialText;
  final String? draftText; // null = không ở chế độ xem lại
  final VoidCallback onMicTap;
  final VoidCallback? onSendDraft;
  final VoidCallback? onDiscardDraft;

  const VoiceInputBar({
    super.key,
    required this.listening,
    required this.busy,
    required this.onMicTap,
    this.voiceMode = false,
    this.partialText = '',
    this.draftText,
    this.onSendDraft,
    this.onDiscardDraft,
  });

  bool get _inDraft => draftText != null;
  bool get _hasPartial => listening && partialText.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          if (_inDraft)
            _draftRow()
          else if (voiceMode)
            _voiceRow()
          else
            _listenRow(),
          const SizedBox(height: 8),
          Text(
            _inDraft
                ? 'Sai thì 🗑 xóa nói lại · thiếu thì 🎙 nói thêm · ưng thì ➤ gửi'
                : voiceMode
                    ? (listening
                        ? 'Đang nghe… nói xong bấm nút đỏ để gửi'
                        : 'Bấm mic và trả lời bằng tiếng Nhật — như một cuộc gọi')
                    : listening
                        ? 'Ngừng một lúc cũng không sao — bấm dừng để xem lại trước khi gửi'
                        : 'Trả lời bằng tiếng Nhật · +15 XP mỗi lượt hội thoại',
            style: AppTextStyles.latin(size: 11, color: AppColors.textFaint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Chế độ thuần giọng nói: chỉ một nút mic to ở giữa ──
  Widget _voiceRow() {
    return _RoundButton(
      color: listening ? AppColors.vocab : AppColors.speaking,
      icon: listening ? Icons.stop_rounded : Icons.mic,
      size: 62,
      onTap: busy ? null : onMicTap,
    );
  }

  // ── Trạng thái chờ / đang nghe ─────────────────────────
  Widget _listenRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: const Color(0xFFE0EEE8), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: listening
                        ? AppColors.vocab
                        : AppColors.speaking.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _hasPartial
                      ? Text(
                          partialText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.jp(
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : Text(
                          listening
                              ? 'Đang nghe... cứ từ từ nói, xong bấm nút đỏ'
                              : 'Nhấn mic rồi nói bằng tiếng Nhật...',
                          style: AppTextStyles.jp(
                            size: 13,
                            weight: FontWeight.w400,
                            color: AppColors.textFaint,
                          ).copyWith(fontStyle: FontStyle.italic),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundButton(
          color: listening ? AppColors.vocab : AppColors.speaking,
          icon: listening ? Icons.stop_rounded : Icons.mic,
          onTap: busy ? null : onMicTap,
        ),
      ],
    );
  }

  // ── Trạng thái XEM LẠI trước khi gửi (chỉ đọc) ─────────
  Widget _draftRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.55), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  // Câu dài (nhiều dòng) thì CUỘN được để xem hết, không cắt "…".
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 96),
                    child: SingleChildScrollView(
                      child: Text(
                        draftText!,
                        style: AppTextStyles.jp(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa, nói lại từ đầu',
                  onPressed: onDiscardDraft,
                  icon: const Icon(Icons.delete_outline,
                      size: 19, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _RoundButton(
          color: AppColors.speaking,
          icon: Icons.mic,
          size: 44,
          onTap: busy ? null : onMicTap, // nói thêm vào câu
        ),
        const SizedBox(width: 6),
        _RoundButton(
          color: AppColors.brand,
          icon: Icons.send_rounded,
          size: 44,
          onTap: busy ? null : onSendDraft,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const _RoundButton({
    required this.color,
    required this.icon,
    required this.onTap,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.48),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

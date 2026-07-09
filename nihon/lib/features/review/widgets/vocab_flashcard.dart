import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/vocab_card.dart';

/// Thẻ flashcard từ vựng – hỗ trợ chỉnh sửa inline trực tiếp ổn định tuyệt đối.
class VocabFlashcard extends StatelessWidget {
  final VocabCard card;
  final bool isEditing;
  final TextEditingController? jpController;
  final TextEditingController? readingController;
  final TextEditingController? viController;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;

  const VocabFlashcard({
    super.key,
    required this.card,
    this.isEditing = false,
    this.jpController,
    this.readingController,
    this.viController,
    this.onSave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2D1F0E),
            blurRadius: 32,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x0D2D1F0E),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Spacer trên cùng để đẩy nội dung chính vào giữa thẻ
          const Spacer(),

          // 1. Reading (Cách đọc)
          if (isEditing)
            TextField(
              controller: readingController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: AppTextStyles.jp(
                size: 17,
                weight: FontWeight.w400,
                color: AppColors.textFaint,
                letterSpacing: 4,
              ),
            )
          else
            Text(
              card.reading,
              style: AppTextStyles.jp(
                size: 17,
                weight: FontWeight.w400,
                color: AppColors.textFaint,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 4),

          // 2. Word (Từ vựng)
          if (isEditing)
            TextField(
              controller: jpController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: AppTextStyles.jp(
                size: 56,
                weight: FontWeight.w700,
                height: 1.05,
                letterSpacing: -0.5,
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                card.word,
                style: AppTextStyles.jp(
                  size: 76,
                  weight: FontWeight.w700,
                  height: 1.05,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 6),

          // 3. Romaji (Phiên âm)
          Text(
            card.romaji,
            style: AppTextStyles.latin(
              size: 13,
              color: AppColors.textFaint,
            ).copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          
          Center(
            child: Container(
              width: 50,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // 4. Meaning (Ý nghĩa)
          if (isEditing)
            TextField(
              controller: viController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: AppTextStyles.latin(
                size: 26,
                weight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            )
          else
            Text(
              card.meaning,
              style: AppTextStyles.latin(
                size: 26,
                weight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),

          // Spacer dưới để đẩy nút Lưu & Xóa xuống dưới cùng
          const Spacer(),

          // 5. Nút Lưu & Xóa ở dưới cùng bên phải thẻ (chỉ hiển thị ở chế độ sửa)
          if (isEditing)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onDelete != null) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vocab,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: onSave,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            // Ở chế độ thường, giữ khoảng trống bằng kích thước nút Lưu để không bị dịch chuyển giao diện
            const SizedBox(height: 44),
        ],
      ),
    );
  }
}

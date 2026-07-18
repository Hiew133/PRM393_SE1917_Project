import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/vocab_card.dart';

/// Thẻ flashcard từ vựng có cơ chế LẬT:
/// - Mặt trước: chỉ hiện từ (kanji/kana) — người học tự nhớ nghĩa.
/// - Chạm vào thẻ để lật ra mặt sau: cách đọc + nghĩa.
/// - Chế độ Admin (isEditing): hiện toàn bộ + chỉnh sửa inline, không lật.
class VocabFlashcard extends StatelessWidget {
  final VocabCard card;
  final bool revealed;
  final VoidCallback? onFlip;
  final bool isEditing;
  final TextEditingController? jpController;
  final TextEditingController? readingController;
  final TextEditingController? viController;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;

  const VocabFlashcard({
    super.key,
    required this.card,
    this.revealed = false,
    this.onFlip,
    this.isEditing = false,
    this.jpController,
    this.readingController,
    this.viController,
    this.onSave,
    this.onDelete,
  });

  BoxDecoration get _cardDecoration => BoxDecoration(
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
      );

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return Container(
        width: double.infinity,
        decoration: _cardDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: _buildEditFace(),
      );
    }

    return GestureDetector(
      onTap: onFlip,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: revealed ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final showBack = t > 0.5;
          Widget face = showBack ? _buildBackFace() : _buildFrontFace();
          // Mặt sau phải xoay ngược lại để chữ không bị soi gương.
          if (showBack) {
            face = Transform(
              transform: Matrix4.rotationY(math.pi),
              alignment: Alignment.center,
              child: face,
            );
          }
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(t * math.pi),
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              decoration: _cardDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: face,
            ),
          );
        },
      ),
    );
  }

  /// Mặt trước: chỉ có từ + gợi ý chạm để lật.
  Widget _buildFrontFace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
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
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app_outlined,
                size: 16, color: AppColors.textFaint),
            const SizedBox(width: 6),
            Text(
              'Chạm để xem đáp án',
              style: AppTextStyles.latin(size: 13, color: AppColors.textFaint),
            ),
          ],
        ),
      ],
    );
  }

  /// Mặt sau: cách đọc + từ + nghĩa.
  Widget _buildBackFace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            card.word,
            style: AppTextStyles.jp(
              size: 56,
              weight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (card.romaji.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            card.romaji,
            style: AppTextStyles.latin(
              size: 13,
              color: AppColors.textFaint,
            ).copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
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
        Text(
          card.meaning,
          style: AppTextStyles.latin(
            size: 26,
            weight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
      ],
    );
  }

  /// Chế độ Admin: chỉnh sửa inline mọi trường, kèm nút Lưu / Xóa.
  Widget _buildEditFace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        TextField(
          controller: readingController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            hintText: 'Cách đọc',
          ),
          style: AppTextStyles.jp(
            size: 17,
            weight: FontWeight.w400,
            color: AppColors.textFaint,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: jpController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            hintText: 'Từ vựng',
          ),
          style: AppTextStyles.jp(
            size: 56,
            weight: FontWeight.w700,
            height: 1.05,
            letterSpacing: -0.5,
          ),
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
        TextField(
          controller: viController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            hintText: 'Ý nghĩa',
          ),
          style: AppTextStyles.latin(
            size: 26,
            weight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Xóa',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vocab,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: onSave,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Lưu',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

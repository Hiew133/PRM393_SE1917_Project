import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/scenario.dart';

/// Các thẻ ghim trên cùng của chế độ THI Nhật 1 (JPD113): bài đọc, tranh,
/// kết quả và chip tiến độ. Chỉ nhận dữ liệu hiển thị — không đụng controller.

/// Thẻ "bài đọc" ghim trên cùng (giai đoạn READING — SV đọc to đoạn văn).
class ExamReadingCard extends StatelessWidget {
  final String jp;
  final String? vi;
  final int points; // điểm phần đọc: Nhật 1 = 30, Nhật 2 = 45
  const ExamReadingCard(
      {super.key, required this.jp, this.vi, this.points = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F2),
        border: Border.all(color: AppColors.speaking.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('BÀI ĐỌC · よんでください',
                    style: AppTextStyles.overline
                        .copyWith(color: AppColors.speaking)),
              ),
              Text('$pointsđ',
                  style: AppTextStyles.latin(
                      size: 10,
                      weight: FontWeight.w800,
                      color: AppColors.speaking)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Bấm mic rồi ĐỌC TO đoạn văn — chỉ cần đọc đúng, không phải trả lời.',
              style: AppTextStyles.latin(
                  size: 10.5, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jp,
                      style: AppTextStyles.jp(
                          size: 15, height: 1.6, weight: FontWeight.w600)),
                  if (vi != null && vi!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(vi!,
                        style: AppTextStyles.latin(
                            size: 12,
                            height: 1.45,
                            color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ TRANH ghim trên cùng (phần TALKING WITH PICTURES) — thay chỗ thẻ bài
/// đọc; emoji to + các gợi ý ghi trên tranh để SV trả lời.
class ExamPictureCard extends StatelessWidget {
  final ExamPicture picture;
  const ExamPictureCard({super.key, required this.picture});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FD),
        border: Border.all(
            color: AppColors.srsMaster.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🖼️', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('TRANH · えを　みて　こたえてください',
                    style: AppTextStyles.overline
                        .copyWith(color: AppColors.srsMaster)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Tranh" — emoji to trong khung.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: AppColors.srsMaster.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(picture.emoji,
                      style: const TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(picture.caption,
                        style: AppTextStyles.jp(
                            size: 15, weight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final h in picture.hints)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(h,
                                style: AppTextStyles.jp(
                                    size: 12, weight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thẻ KẾT QUẢ ước lượng sau khi thi xong — tính từ điểm AI chấm từng lượt
/// ([scores]: [0]=đọc bài, [1..]=các câu hỏi), quy về đúng cơ cấu đề:
/// - Nhật 1 (JPD113): ĐỌC 30đ + 4 câu × 15đ + tác phong 10đ (mặc định).
/// - Nhật 2 (JPD123): ĐỌC 45đ + 3 câu × 15đ + tác phong 10đ.
/// Tác phong ước theo trung bình các lượt vì AI không thấy tác phong thật.
class ExamResultCard extends StatelessWidget {
  final List<int?> scores;
  final int readingMax; // 30 (Nhật 1) | 45 (Nhật 2)
  final int questionCount; // 4 (Nhật 1) | 3 (Nhật 2)
  final int questionMax; // 15đ mỗi câu
  final int mannerMax; // 10đ tác phong
  const ExamResultCard({
    super.key,
    required this.scores,
    this.readingMax = 30,
    this.questionCount = 4,
    this.questionMax = 15,
    this.mannerMax = 10,
  });

  @override
  Widget build(BuildContext context) {
    int? at(int i) => i < scores.length ? scores[i] : null;

    final turns = questionCount + 1; // đọc bài + các câu hỏi
    final graded = [for (var i = 0; i < turns; i++) at(i)].whereType<int>();
    final avg = graded.isEmpty
        ? 0
        : graded.reduce((a, b) => a + b) / graded.length;

    final reading = ((at(0) ?? 0) * readingMax / 100).round();
    final qs = [
      for (var i = 1; i <= questionCount; i++)
        ((at(i) ?? 0) * questionMax / 100).round(),
    ];
    final manner = (avg * mannerMax / 100).round();
    final total = reading + qs.reduce((a, b) => a + b) + manner;

    Widget chip(String label, int pts, int max) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border.all(color: AppColors.speaking.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTextStyles.latin(
                    size: 11, color: AppColors.textMuted)),
            const SizedBox(width: 5),
            Text('$pts/$max',
                style: AppTextStyles.latin(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: AppColors.speaking)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F2),
        border: Border.all(color: AppColors.speaking.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('KẾT QUẢ (ước lượng)',
                    style: AppTextStyles.overline
                        .copyWith(color: AppColors.speaking)),
              ),
              Text('$total',
                  style: AppTextStyles.latin(
                      size: 20,
                      weight: FontWeight.w800,
                      color: AppColors.speaking)),
              Text('/100',
                  style: AppTextStyles.latin(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              chip('Đọc bài', reading, readingMax),
              for (var i = 0; i < questionCount; i++)
                chip('Câu ${i + 1}', qs[i], questionMax),
              chip('Tác phong', manner, mannerMax),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'AI chấm ước lượng qua nhận diện giọng nói — điểm tham khảo để ôn tập.',
            style: AppTextStyles.latin(size: 10, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}

/// Chip tiến độ "Câu x/4" (chế độ thi Nhật 1).
class ExamProgressChip extends StatelessWidget {
  final String label;
  final bool done;
  const ExamProgressChip({super.key, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.speaking : AppColors.srsMaster;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(done ? Icons.check_circle : Icons.timelapse,
                    size: 13, color: color),
                const SizedBox(width: 5),
                Text(label,
                    style: AppTextStyles.latin(
                        size: 11, weight: FontWeight.w700, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

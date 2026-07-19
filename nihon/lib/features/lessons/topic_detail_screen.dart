import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'topic_content.dart';

/// Hiển thị nội dung một chủ đề: từ vựng + các bài đọc ngắn có dịch.
class TopicDetailScreen extends StatelessWidget {
  const TopicDetailScreen({super.key, required this.topic, required this.color});

  final TopicContent topic;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          topic.titleVi,
          style: AppTextStyles.latin(size: 20, weight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.titleJp, style: AppTextStyles.jp(size: 34, weight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text('${topic.vocab.length} từ vựng · ${topic.readings.length} bài đọc',
                    style: AppTextStyles.latin(size: 13, color: AppColors.textMuted, weight: FontWeight.w600)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Từ vựng', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < topic.vocab.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _vocabRow(topic.vocab[i]),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Bài đọc · luyện dịch', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 4),
          Text(
            'Đọc câu tiếng Nhật, tự gõ bản dịch của bạn rồi mới xem đáp án.',
            style: AppTextStyles.latin(size: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          for (final r in topic.readings) ...[
            _ReadingPracticeCard(reading: r, color: color),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _vocabRow(TopicVocab v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.reading, style: AppTextStyles.jp(size: 12, color: AppColors.textMuted)),
                Text(v.word, style: AppTextStyles.jp(size: 20, weight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Flexible(
            child: Text(
              v.meaning,
              textAlign: TextAlign.right,
              style: AppTextStyles.latin(size: 14, weight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

}

/// Thẻ LUYỆN DỊCH một bài đọc: hiện câu tiếng Nhật + ô gõ bản dịch. Bản dịch
/// tham khảo chỉ hiện SAU KHI người học đã gõ và bấm "Xem đáp án".
class _ReadingPracticeCard extends StatefulWidget {
  const _ReadingPracticeCard({required this.reading, required this.color});

  final TopicReading reading;
  final Color color;

  @override
  State<_ReadingPracticeCard> createState() => _ReadingPracticeCardState();
}

class _ReadingPracticeCardState extends State<_ReadingPracticeCard> {
  final TextEditingController _input = TextEditingController();
  bool _submitted = false;
  String _userAnswer = '';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _input.text.trim();
    if (text.isEmpty) return; // phải gõ gì đó mới được xem đáp án
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _userAnswer = text;
      _submitted = true;
    });
  }

  void _retry() {
    setState(() {
      _submitted = false;
      _input.clear();
      _userAnswer = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.reading.jp,
            style: AppTextStyles.jp(
                size: 17,
                height: 1.7,
                weight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          if (!_submitted) ...[
            // Ô gõ bản dịch của người học.
            TextField(
              controller: _input,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Gõ bản dịch tiếng Việt của bạn…',
                hintStyle: AppTextStyles.latin(
                    size: 13, color: AppColors.textFaint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.color, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: AppTextStyles.latin(size: 13.5, height: 1.5),
            ),
            const SizedBox(height: 10),
            // Chỉ bật nút khi đã gõ gì đó.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _input,
              builder: (context, value, _) {
                final ready = value.text.trim().isNotEmpty;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: ready ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          widget.color.withValues(alpha: 0.25),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(
                      ready ? 'Xem đáp án' : 'Gõ bản dịch trước đã…',
                      style: AppTextStyles.latin(
                          size: 13.5, weight: FontWeight.w700),
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            // Bản dịch của người học.
            Text('BẢN DỊCH CỦA BẠN',
                style: AppTextStyles.latin(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: AppColors.textFaint)),
            const SizedBox(height: 4),
            Text(_userAnswer,
                style: AppTextStyles.latin(
                    size: 13.5, height: 1.6, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            // Bản dịch tham khảo.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: widget.color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BẢN DỊCH THAM KHẢO',
                      style: AppTextStyles.latin(
                          size: 10.5,
                          weight: FontWeight.w800,
                          color: widget.color)),
                  const SizedBox(height: 4),
                  Text(widget.reading.vi,
                      style: AppTextStyles.latin(
                          size: 13.5,
                          height: 1.6,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Dịch lại'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  textStyle: AppTextStyles.latin(
                      size: 12.5, weight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

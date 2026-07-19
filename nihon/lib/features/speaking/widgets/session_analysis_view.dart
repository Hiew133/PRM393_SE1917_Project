import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/chat_message.dart';
import '../services/ai_conversation_service.dart';
import 'chat_bubble.dart';

/// Màn PHÂN TÍCH & GÓP Ý cuối buổi hội thoại (chế độ Tự do / JPD316).
/// Hiện sau khi bấm "Kết thúc": điểm tổng, nhận xét, điểm mạnh/cần cải thiện,
/// góp ý từng câu, và bản ghi hội thoại (thu gọn).
class SessionAnalysisView extends StatelessWidget {
  final SessionAnalysis analysis;
  final List<ChatMessage> messages;
  final void Function(String japanese)? onListen;

  const SessionAnalysisView({
    super.key,
    required this.analysis,
    required this.messages,
    this.onListen,
  });

  Color get _scoreColor {
    final s = analysis.overallScore;
    if (s >= 80) return const Color(0xFF16A34A);
    if (s >= 60) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // ── Điểm tổng + nhận xét chung ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: analysis.overallScore / 100,
                        strokeWidth: 7,
                        backgroundColor: AppColors.border,
                        color: _scoreColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${analysis.overallScore}',
                            style: AppTextStyles.latin(
                                size: 24,
                                weight: FontWeight.w800,
                                color: _scoreColor)),
                        Text('/100',
                            style: AppTextStyles.latin(
                                size: 10, color: AppColors.textFaint)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phân tích buổi hội thoại',
                        style: AppTextStyles.latin(
                            size: 15, weight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(analysis.summary,
                        style: AppTextStyles.latin(
                            size: 13,
                            color: AppColors.textSecondary,
                            height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Điểm mạnh ──
        if (analysis.strengths.isNotEmpty)
          _listCard(
            title: 'Điểm mạnh',
            emoji: '💪',
            color: const Color(0xFF16A34A),
            items: analysis.strengths,
          ),
        if (analysis.improvements.isNotEmpty) ...[
          const SizedBox(height: 14),
          _listCard(
            title: 'Cần cải thiện',
            emoji: '📌',
            color: const Color(0xFFD97706),
            items: analysis.improvements,
          ),
        ],

        // ── Góp ý từng câu ──
        if (analysis.sentenceNotes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✏️', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Text('Góp ý từng câu',
                        style: AppTextStyles.latin(
                            size: 14, weight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                for (final note in analysis.sentenceNotes) _sentenceNote(note),
              ],
            ),
          ),
        ],

        // ── Bản ghi hội thoại (thu gọn) ──
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 18),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Text('Xem lại hội thoại',
                      style: AppTextStyles.latin(
                          size: 14, weight: FontWeight.w800)),
                ],
              ),
              children: [
                for (final m in messages)
                  if (!m.isPending && m.japanese.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ChatBubble(
                        message: m,
                        onListen: m.fromUser || onListen == null
                            ? null
                            : () => onListen!(m.japanese),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _listCard({
    required String title,
    required String emoji,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.latin(size: 14, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item,
                        style: AppTextStyles.latin(
                            size: 13,
                            color: AppColors.textSecondary,
                            height: 1.45)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sentenceNote(SentenceNote note) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Câu người học đã nói.
          Text('Bạn nói: ${note.original}',
              style: AppTextStyles.jp(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(note.issue,
              style: AppTextStyles.latin(
                  size: 12.5, color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 10),
          // Cách nói tốt hơn + nút nghe.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AppColors.speaking),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.better,
                        style: AppTextStyles.jp(
                            size: 14.5,
                            weight: FontWeight.w700,
                            color: AppColors.speaking)),
                    if (note.betterReading.isNotEmpty)
                      Text(note.betterReading,
                          style: AppTextStyles.jp(
                              size: 11.5, color: AppColors.textFaint)),
                  ],
                ),
              ),
              if (onListen != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Nghe câu gợi ý',
                  onPressed: () => onListen!(note.better),
                  icon: const Icon(Icons.volume_up_rounded,
                      size: 19, color: AppColors.speaking),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

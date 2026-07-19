import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/tts_helper.dart';
import 'services/speaking_history_service.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/exam_cards.dart';
import 'widgets/session_analysis_view.dart';

/// LỊCH SỬ các buổi luyện nói: danh sách buổi (mới → cũ), bấm vào xem lại
/// phân tích/điểm + toàn bộ hội thoại.
class SpeakingHistoryScreen extends StatelessWidget {
  const SpeakingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('Lịch sử luyện nói', style: AppTextStyles.screenTitle),
      ),
      body: FutureBuilder<List<SpeakingSessionRecord>>(
        future: SpeakingHistoryService.listSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.speaking));
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎙️', style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 14),
                    Text('Chưa có buổi luyện nào',
                        style: AppTextStyles.latin(
                            size: 16, weight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      'Hoàn thành một buổi hội thoại hoặc bài thi nói, '
                      'kết quả sẽ được lưu lại ở đây.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.latin(
                          size: 13, color: AppColors.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _SessionTile(record: sessions[i]),
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SpeakingSessionRecord record;
  const _SessionTile({required this.record});

  Color get _modeColor {
    switch (record.mode) {
      case 'nihon1':
        return AppColors.speaking;
      case 'nihon2':
        return AppColors.reading;
      case 'jpd316':
        return AppColors.kanji;
      default:
        return AppColors.srsMaster;
    }
  }

  String get _dateLabel {
    final d = record.createdAt;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} · ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _SessionDetailScreen(record: record),
        )),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Điểm tổng.
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _modeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  record.score?.toString() ?? '—',
                  style: AppTextStyles.latin(
                      size: 16, weight: FontWeight.w800, color: _modeColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _modeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(record.modeLabel,
                              style: AppTextStyles.latin(
                                  size: 10,
                                  weight: FontWeight.w800,
                                  color: _modeColor)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_dateLabel,
                              style: AppTextStyles.latin(
                                  size: 11, color: AppColors.textFaint)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      record.title.isEmpty ? 'Buổi luyện nói' : record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.latin(
                          size: 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text('${record.transcript.length} lượt hội thoại',
                        style: AppTextStyles.latin(
                            size: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chi tiết một buổi đã lưu: phân tích (nếu là hội thoại) / bảng điểm thi
/// (nếu là buổi thi) + toàn bộ transcript.
class _SessionDetailScreen extends StatelessWidget {
  final SpeakingSessionRecord record;
  const _SessionDetailScreen({required this.record});

  bool get _isExam => record.mode == 'nihon1' || record.mode == 'nihon2';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          record.title.isEmpty ? record.modeLabel : record.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.screenTitle,
        ),
      ),
      body: record.analysis != null
          ? SessionAnalysisView(
              analysis: record.analysis!,
              messages: record.transcript,
              onListen: speakJapanese,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (_isExam)
                  ExamResultCard(
                    scores: record.examScores,
                    readingMax: record.mode == 'nihon2' ? 45 : 30,
                    questionCount: record.mode == 'nihon2' ? 3 : 4,
                  ),
                const SizedBox(height: 8),
                for (final m in record.transcript)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ChatBubble(
                      message: m,
                      onListen:
                          m.fromUser ? null : () => speakJapanese(m.japanese),
                    ),
                  ),
              ],
            ),
    );
  }
}

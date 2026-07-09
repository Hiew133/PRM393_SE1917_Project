import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../admin/data/admin_repository.dart';
import '../admin/exam_scenario.dart';
import '../admin/models/admin_models.dart';
import '../admin/screens/student_draw_screen.dart';
import 'models/nihon1_exam_sets.dart';
import 'speaking_screen.dart';

/// Màn CHỌN TRÌNH ĐỘ trước khi vào hội thoại.
///
/// 3 chế độ: Nhật 1 (thi JPD113), Nhật 3 (thi JPD316), Tự do.
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  // ── Điều hướng từng chế độ ──────────────────────────────
  void _startNihon1(BuildContext context, Nihon1Exam exam) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SpeakingScreen(
        examScenario: exam.toScenario(),
        title: exam.title,
      ),
    ));
  }

  /// Chọn chế độ Nhật 1: mở bottom sheet bốc ngẫu nhiên / chọn đề (đề đã
  /// XUẤT BẢN trên Firestore, giảng viên soạn qua Admin).
  Future<void> _openNihon1(BuildContext context) async {
    final exams = AdminRepository.instance.publishedNihon1Exams;
    if (exams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Chưa có đề Nhật 1 nào được xuất bản để luyện.')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('THI NHẬT 1 · BỐC ĐỀ', style: AppTextStyles.overline),
              ),
            ),
            ListTile(
              leading: const Text('🎲', style: TextStyle(fontSize: 22)),
              title: Text('Bốc ngẫu nhiên',
                  style:
                      AppTextStyles.latin(size: 14, weight: FontWeight.w700)),
              subtitle: Text('Bốc 1 trong ${exams.length} đề',
                  style: AppTextStyles.latin(
                      size: 11, color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _startNihon1(
                    context, exams[Random().nextInt(exams.length)]);
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final exam in exams)
                    ListTile(
                      leading: const Text('📄', style: TextStyle(fontSize: 18)),
                      title: Text(exam.title,
                          style: AppTextStyles.latin(
                              size: 13, weight: FontWeight.w600)),
                      subtitle: Text(
                          '📖 đọc to · ${exam.pictureEmoji} ${exam.pictureCaption} · 💬 tự do',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.jp(
                              size: 11, color: AppColors.textMuted)),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _startNihon1(context, exam);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _startFree(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SpeakingScreen()),
    );
  }

  /// Các tình huống 会話 đã soạn thuộc đề đã xuất bản (kèm đề chứa nó).
  List<(Exam, ConversationSituation)> _examSituations() {
    final admin = AdminRepository.instance;
    final out = <(Exam, ConversationSituation)>[];
    for (final e
        in admin.exams.where((e) => e.status == ExamStatus.published)) {
      for (final s in admin.situationsForExam(e.id).where((s) => s.drafted)) {
        out.add((e, s));
      }
    }
    return out;
  }

  void _noSituationSnack(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Chưa có tình huống 会話 nào được xuất bản để luyện.')),
      );

  /// 🎲 Bốc ngẫu nhiên 1 đề đã xuất bản → mở nghi thức bốc (S07).
  void _randomDraw(BuildContext context) {
    final admin = AdminRepository.instance;
    final exams = admin.exams
        .where((e) =>
            e.status == ExamStatus.published &&
            admin.situationsForExam(e.id).any((s) => s.drafted))
        .toList();
    if (exams.isEmpty) {
      _noSituationSnack(context);
      return;
    }
    final exam = exams[Random().nextInt(exams.length)];
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StudentDrawScreen(exam: exam, autoDraw: true),
    ));
  }

  void _startSituation(BuildContext context, Exam e, ConversationSituation s) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SpeakingScreen(
        examScenario: buildExamScenario(s),
        title: s.title,
      ),
    ));
  }

  /// Chọn chế độ Nhật 3: mở bottom sheet bốc ngẫu nhiên / chọn tình huống.
  Future<void> _openJpd316(BuildContext context) async {
    final list = _examSituations();
    if (list.isEmpty) {
      _noSituationSnack(context);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('THI NHẬT 3 · CHỌN TÌNH HUỐNG 会話',
                    style: AppTextStyles.overline),
              ),
            ),
            ListTile(
              leading: const Text('🎲', style: TextStyle(fontSize: 22)),
              title: Text('Bốc ngẫu nhiên',
                  style: AppTextStyles.latin(
                      size: 14, weight: FontWeight.w700)),
              subtitle: Text('Quay bốc 1 tình huống như khi thi',
                  style: AppTextStyles.latin(
                      size: 11, color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _randomDraw(context);
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final (exam, s) in list)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF5F0FF),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(s.baseTemplate,
                            style: AppTextStyles.jp(
                                size: 10,
                                weight: FontWeight.w700,
                                color: AppColors.kanji)),
                      ),
                      title: Text(s.title,
                          style: AppTextStyles.latin(
                              size: 13, weight: FontWeight.w600)),
                      subtitle: Text(
                          s.grammar.isEmpty
                              ? exam.title
                              : s.grammar.join(' ・ '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.jp(
                              size: 11, color: AppColors.textMuted)),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _startSituation(context, exam, s);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('Luyện nói với AI', style: AppTextStyles.screenTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('Chọn trình độ / chế độ', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 4),
            Text('Mỗi chế độ có cách dẫn dắt khác nhau.',
                style:
                    AppTextStyles.latin(size: 12, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            _LevelCard(
              emoji: '🟢',
              color: AppColors.speaking,
              title: 'Nhật 1 · Thi nói JPD113',
              subtitle: 'Bốc đề · đọc to + hỏi theo tranh + tự do · AI giám khảo',
              onTap: () => _openNihon1(context),
            ),
            const SizedBox(height: 12),
            _LevelCard(
              emoji: '🟣',
              color: AppColors.kanji,
              title: 'Nhật 3 · Thi nói JPD316',
              subtitle: 'Hội thoại 会話 theo đề giảng viên soạn',
              onTap: () => _openJpd316(context),
            ),
            const SizedBox(height: 12),
            _LevelCard(
              emoji: '💬',
              color: AppColors.srsMaster,
              title: 'Tự do',
              subtitle: 'Trò chuyện tiếng Nhật thoải mái, không theo đề',
              onTap: () => _startFree(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String emoji;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LevelCard({
    required this.emoji,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45)),
            color: color.withValues(alpha: 0.06),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.latin(
                            size: 15, weight: FontWeight.w700, color: color)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: AppTextStyles.latin(
                            size: 12,
                            height: 1.35,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../speaking/models/nihon1_exam_sets.dart';
import '../data/admin_repository.dart';
import '../models/admin_models.dart';
import 'exam_structure_screen.dart';
import 'nihon1_exam_editor_screen.dart';

/// S01 — Danh sách đề thi Nói (Admin). Toggle 2 chuẩn đề: JPD316 / JPD113.
class ExamListScreen extends StatefulWidget {
  /// Tab mở sẵn khi vào (0 = JPD316, 1 = JPD113) — trang chủ Admin truyền vào.
  final int initialTab;
  const ExamListScreen({super.key, this.initialTab = 0});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  final _repo = AdminRepository.instance;

  /// 0 = JPD316 (会話 + Q&A), 1 = JPD113 (Nhật 1: đọc + tranh + tự do).
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _repo,
          builder: (context, _) {
            return Stack(
              children: [
                Column(
                  children: [
                    _header(),
                    _tabBar(),
                    if (_repo.error != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          border: Border.all(color: const Color(0xFFFECACA)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(maxHeight: 110),
                        child: SingleChildScrollView(
                          child: Text(_repo.error!,
                              style: AppTextStyles.latin(
                                  size: 12, color: AppColors.vocab)),
                        ),
                      ),
                    Expanded(
                        child: _tab == 0 ? _jpd316List() : _nihon1List()),
                  ],
                ),
                Positioned(right: 20, bottom: 20, child: _fab()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Đề thi Nói',
                        style: AppTextStyles.latin(
                            size: 20, weight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('話す',
                        style: AppTextStyles.jp(
                            size: 18, color: AppColors.speaking)),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('ADMIN',
                          style: AppTextStyles.latin(
                              size: 9,
                              weight: FontWeight.w800,
                              color: const Color(0xFFF7C547),
                              letterSpacing: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                    _tab == 0
                        ? 'JPD316 · chuẩn 会話 55 + Q&A 45'
                        : 'JPD113 · đọc 30 + 4 câu 60 + tác phong 10',
                    style:
                        AppTextStyles.latin(size: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle 2 chuẩn đề.
  Widget _tabBar() {
    Widget tab(int i, String jp, String vi, Color color) {
      final on = _tab == i;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? color : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: on ? color : AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(jp,
                    style: AppTextStyles.jp(
                        size: 13,
                        weight: FontWeight.w700,
                        color: on ? Colors.white : color)),
                const SizedBox(width: 6),
                Text(vi,
                    style: AppTextStyles.latin(
                        size: 12,
                        weight: FontWeight.w700,
                        color: on ? Colors.white : AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          tab(0, '会話', 'Nhật 3', AppColors.kanji),
          const SizedBox(width: 8),
          tab(1, '日本語１', 'Nhật 1', AppColors.speaking),
        ],
      ),
    );
  }

  /// Danh sách đề JPD316.
  Widget _jpd316List() {
    final current =
        _repo.exams.where((e) => e.status != ExamStatus.archived).toList();
    final past =
        _repo.exams.where((e) => e.status == ExamStatus.archived).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 90),
      children: [
        _sectionLabel('HỌC KỲ HIỆN TẠI'),
        for (final e in current) _ExamCard(exam: e),
        if (past.isNotEmpty) ...[
          const SizedBox(height: 4),
          _sectionLabel('KỲ TRƯỚC'),
          for (final e in past) _ExamCard(exam: e),
        ],
      ],
    );
  }

  /// Danh sách đề Nhật 1 (JPD113).
  Widget _nihon1List() {
    final list = [..._repo.nihon1Exams]..sort((a, b) => a.id.compareTo(b.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 90),
      children: [
        _sectionLabel('ĐỀ THI NÓI NHẬT 1'),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Chưa có đề nào. Bấm "Tạo đề Nhật 1" để thêm.',
                style:
                    AppTextStyles.latin(size: 13, color: AppColors.textMuted)),
          ),
        for (final e in list)
          _Nihon1Card(
            exam: e,
            onEdit: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Nihon1ExamEditorScreen(exam: e))),
          ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: AppTextStyles.overline),
      );

  /// Form TẠO ĐỀ dùng chung cho cả 2 chuẩn: hỏi tên đề → tạo đề (nháp) → mở
  /// editor tương ứng (S02 cấu trúc cho JPD316, editor phẳng cho Nhật 1).
  Future<void> _createExam() async {
    final isNihon1 = _tab == 1;
    final title = await _askExamTitle(
        isNihon1 ? 'VD: Đề 6 · Đọc … — Tranh …' : 'VD: Thi cuối kỳ — Đề C');
    if (title == null || !mounted) return; // huỷ
    if (isNihon1) {
      final exam = await _repo.createNihon1Exam(title: title);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => Nihon1ExamEditorScreen(exam: exam)));
    } else {
      final exam = await _repo.createExam(
          title: title.isEmpty ? 'Đề JPD316 mới' : title,
          lessonRange: 'Bài 1~5');
      if (!mounted) return;
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ExamStructureScreen(exam: exam)));
    }
  }

  /// Dialog nhập tên đề. Trả null nếu huỷ, hoặc tên (có thể rỗng) nếu bấm Tạo.
  Future<String?> _askExamTitle(String hint) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo đề mới'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          decoration: InputDecoration(
            labelText: 'Tên đề',
            hintText: hint,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Tạo')),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  Widget _fab() {
    return Material(
      color: AppColors.speaking,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: _createExam,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Tạo đề mới',
                  style: AppTextStyles.latin(
                      size: 14,
                      weight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ đề Nhật 1 trong danh sách admin.
class _Nihon1Card extends StatelessWidget {
  final Nihon1Exam exam;
  final VoidCallback onEdit;
  const _Nihon1Card({required this.exam, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEFF8F2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(exam.pictureEmoji,
                      style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.latin(
                              size: 14, weight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                          '📖 đọc to · ${exam.pictureQuestions.where((q) => q.trim().isNotEmpty).length} câu tranh · 💬 tự do',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.latin(
                              size: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusChip(exam.published),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(bool published) {
    final (bg, fg) = published
        ? (const Color(0xFFF0FDF4), AppColors.speaking)
        : (AppColors.surfaceAlt, AppColors.listening);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(published ? 'Xuất bản' : 'Nháp',
          style: AppTextStyles.latin(
              size: 10, weight: FontWeight.w700, color: fg)),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository.instance;
    final situationDone =
        repo.situationsForExam(exam.id).where((s) => s.drafted).length;
    final qaDone = repo.questionsForExam(exam.id).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ExamStructureScreen(exam: exam)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exam.title,
                                  style: AppTextStyles.latin(
                                      size: 15, weight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text('${exam.lessonRange} · ${exam.updatedLabel}',
                                  style: AppTextStyles.latin(
                                      size: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        _statusChip(exam.status),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: _partBox(
                            jp: '会話',
                            color: AppColors.kanji,
                            bg: const Color(0xFFF5F0FF),
                            points: exam.conversationPoints,
                            sub: '$situationDone/${exam.situationTarget} tình huống',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _partBox(
                            jp: 'Q&A',
                            color: AppColors.srsMaster,
                            bg: const Color(0xFFE8EFFB),
                            points: exam.qaPoints,
                            sub: '$qaDone câu · 3 nhóm',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFFFAF6EE),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        exam.studentsTaken > 0
                            ? '${exam.studentsTaken} SV đã thi · TB ${exam.avgScore}đ'
                            : 'Chưa có SV thi',
                        style: AppTextStyles.latin(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                    ),
                    Text(
                      exam.status == ExamStatus.draft ? 'Tiếp tục →' : 'Sửa →',
                      style: AppTextStyles.latin(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppColors.brand),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(ExamStatus status) {
    final (bg, fg) = switch (status) {
      ExamStatus.published => (const Color(0xFFF0FDF4), AppColors.speaking),
      ExamStatus.draft => (AppColors.surfaceAlt, AppColors.listening),
      ExamStatus.archived => (AppColors.border, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(status.label,
          style: AppTextStyles.latin(
              size: 10, weight: FontWeight.w700, color: fg)),
    );
  }

  Widget _partBox({
    required String jp,
    required Color color,
    required Color bg,
    required int points,
    required String sub,
  }) {
    final isJp = jp == '会話';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isJp
                  ? Text(jp,
                      style: AppTextStyles.jp(
                          size: 12, weight: FontWeight.w700, color: color))
                  : Text(jp,
                      style: AppTextStyles.latin(
                          size: 12, weight: FontWeight.w700, color: color)),
              Text('$pointsđ',
                  style: AppTextStyles.latin(
                      size: 13, weight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 1),
          Text(sub,
              style: AppTextStyles.latin(size: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

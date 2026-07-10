import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'data/admin_repository.dart';
import 'models/admin_models.dart';
import 'exam_editor_screen.dart';
import 'question_bank_screen.dart';
import 'situation_bank_screen.dart';

/// S02 — Cấu trúc đề (100đ = 会話 55 + Q&A 45).
class ExamStructureScreen extends StatelessWidget {
  final Exam exam;
  const ExamStructureScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final repo = AdminRepository.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: repo,
          builder: (context, _) {
            final g1 = repo.questionsForExam(exam.id, QaGroup.withImage).length;
            final g2 = repo.questionsForExam(exam.id, QaGroup.noImage).length;
            final g3 = repo.questionsForExam(exam.id, QaGroup.free).length;
            final situationsDone =
                repo.situationsForExam(exam.id).where((s) => s.drafted).length;
            return Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      _totalBar(),
                      const SizedBox(height: 18),
                      Text('CÁC PHẦN THI', style: AppTextStyles.overline),
                      const SizedBox(height: 10),
                      _conversationCard(context, situationsDone),
                      const SizedBox(height: 10),
                      _qaCard(context, g1, g2, g3),
                      const SizedBox(height: 10),
                      _prepCard(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _backButton(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyles.latin(size: 16, weight: FontWeight.w700)),
                Text('Cấu trúc đề · ${exam.status.label}',
                    style:
                        AppTextStyles.latin(size: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          _publishButton(context),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ExamEditorScreen(exam: exam)),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _publishButton(BuildContext context) {
    final repo = AdminRepository.instance;
    final published = exam.status == ExamStatus.published;
    return GestureDetector(
      onTap: () => repo.updateExamStatus(
          exam, published ? ExamStatus.draft : ExamStatus.published),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: published ? AppColors.border : AppColors.speaking,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(published ? 'Chuyển nháp' : 'Xuất bản',
            style: AppTextStyles.latin(
                size: 12,
                weight: FontWeight.w700,
                color: published ? AppColors.textSecondary : Colors.white)),
      ),
    );
  }

  Widget _backButton(BuildContext context) => GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
        ),
      );

  Widget _totalBar() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.resumeCard,
        borderRadius: BorderRadius.circular(16),
      ),
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
                    Text('TỔNG ĐIỂM ĐỀ',
                        style: AppTextStyles.latin(
                            size: 11,
                            weight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 0.6)),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: '${exam.totalPoints}',
                          style: AppTextStyles.latin(
                              size: 30,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                      TextSpan(
                          text: ' điểm',
                          style: AppTextStyles.latin(
                              size: 15,
                              weight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.6))),
                    ])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TỔNG THỜI GIAN',
                      style: AppTextStyles.latin(
                          size: 11,
                          weight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5))),
                  Text('~10 phút',
                      style: AppTextStyles.latin(
                          size: 20,
                          weight: FontWeight.w700,
                          color: const Color(0xFFF7C547))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(children: [
                Expanded(
                    flex: exam.conversationPoints,
                    child: Container(color: AppColors.kanji)),
                const SizedBox(width: 3),
                Expanded(
                    flex: exam.qaPoints,
                    child: Container(color: AppColors.srsMaster)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conversationCard(BuildContext context, int situationsDone) {
    final enough = situationsDone >= exam.situationTarget;
    return _PartCard(
      iconJp: '会',
      iconColor: AppColors.kanji,
      titleJp: '会話',
      titleVi: 'Hội thoại',
      subtitle:
          '${exam.conversationMinutes} phút · ${exam.conversationPrepSeconds}s chuẩn bị · 1 tình huống 会話',
      points: exam.conversationPoints,
      pointColor: AppColors.kanji,
      statusOk: enough,
      statusText: enough ? 'Đủ' : 'Thiếu',
      footerLeft: enough ? 'Tình huống 会話 · đã soạn' : 'Chưa soạn tình huống 会話',
      onManage: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => SituationBankScreen(examId: exam.id)),
      ),
    );
  }

  Widget _qaCard(BuildContext context, int g1, int g2, int g3) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _PartCard.inner(
            iconJp: 'Q&A',
            iconColor: AppColors.srsMaster,
            titleVi: 'Hỏi đáp',
            subtitle: '${exam.qaMinutes} phút · 3 câu thuộc 3 nhóm',
            points: exam.qaPoints,
            pointColor: AppColors.srsMaster,
            statusOk: g3 > 0,
            statusText: g3 > 0 ? 'Đủ' : 'Thiếu',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                _qaGroupRow(QaGroup.withImage, g1, context),
                const SizedBox(height: 7),
                _qaGroupRow(QaGroup.noImage, g2, context),
                const SizedBox(height: 7),
                _qaGroupRow(QaGroup.free, g3, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qaGroupRow(QaGroup g, int count, BuildContext context) {
    final isFree = g == QaGroup.free;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuestionBankScreen(examId: exam.id)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isFree ? AppColors.surfaceAlt : const Color(0xFFE8EFFB),
          borderRadius: BorderRadius.circular(10),
          border: isFree
              ? Border.all(color: const Color(0xFFF0D8A0))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFree ? AppColors.listening : AppColors.srsMaster),
              alignment: Alignment.center,
              child: Text('${g.number}',
                  style: AppTextStyles.latin(
                      size: 11, weight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${g.label} ${g.emoji}',
                  style: AppTextStyles.latin(size: 12, weight: FontWeight.w700)),
            ),
            Text(
              count > 0 ? '✓ $count câu' : '+ thêm',
              style: AppTextStyles.latin(
                  size: 11,
                  weight: FontWeight.w700,
                  color: count > 0 ? AppColors.speaking : AppColors.listening),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prepCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.timer_outlined, color: AppColors.textMuted),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thời gian chuẩn bị',
                    style:
                        AppTextStyles.latin(size: 14, weight: FontWeight.w700)),
                Text('Gọi SV, nhập điểm, dự trù sự cố',
                    style: AppTextStyles.latin(
                        size: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text('${exam.prepMinutes} phút',
              style: AppTextStyles.latin(
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }

}

/// Thẻ một phần thi (会話 / Q&A).
class _PartCard extends StatelessWidget {
  final String iconJp;
  final Color iconColor;
  final String? titleJp;
  final String titleVi;
  final String subtitle;
  final int points;
  final Color pointColor;
  final bool statusOk;
  final String statusText;
  final String? footerLeft;
  final VoidCallback? onManage;
  final bool _inner;

  const _PartCard({
    required this.iconJp,
    required this.iconColor,
    this.titleJp,
    required this.titleVi,
    required this.subtitle,
    required this.points,
    required this.pointColor,
    required this.statusOk,
    required this.statusText,
    this.footerLeft,
    this.onManage,
  }) : _inner = false;

  const _PartCard.inner({
    required this.iconJp,
    required this.iconColor,
    required this.titleVi,
    required this.subtitle,
    required this.points,
    required this.pointColor,
    required this.statusOk,
    required this.statusText,
  })  : titleJp = null,
        footerLeft = null,
        onManage = null,
        _inner = true;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: iconColor, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: iconJp.length <= 1
                    ? Text(iconJp,
                        style: AppTextStyles.jp(
                            size: 20,
                            weight: FontWeight.w700,
                            color: Colors.white))
                    : Text(iconJp,
                        style: AppTextStyles.latin(
                            size: 15,
                            weight: FontWeight.w700,
                            color: Colors.white)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (titleJp != null) ...[
                          Text(titleJp!,
                              style: AppTextStyles.jp(
                                  size: 15, weight: FontWeight.w700)),
                          const SizedBox(width: 7),
                        ],
                        Text(titleVi,
                            style: AppTextStyles.latin(
                                size: titleJp != null ? 13 : 15,
                                weight: FontWeight.w700,
                                color: titleJp != null
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTextStyles.latin(
                            size: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$pointsđ',
                      style: AppTextStyles.latin(
                          size: 20,
                          weight: FontWeight.w800,
                          color: pointColor)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusOk
                                ? AppColors.speaking
                                : AppColors.listening),
                      ),
                      const SizedBox(width: 3),
                      Text(statusText,
                          style: AppTextStyles.latin(
                              size: 10,
                              weight: FontWeight.w600,
                              color: statusOk
                                  ? AppColors.speaking
                                  : AppColors.listening)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (footerLeft != null)
          GestureDetector(
            onTap: onManage,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF6EE),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(footerLeft!,
                        style: AppTextStyles.latin(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                  Text('Quản lý →',
                      style: AppTextStyles.latin(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppColors.brand)),
                ],
              ),
            ),
          ),
      ],
    );

    if (_inner) return body;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}

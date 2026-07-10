import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'data/admin_repository.dart';
import 'models/admin_models.dart';
import 'question_editor_screen.dart';

/// S05 — Ngân hàng câu hỏi Q&A (質問リスト) của 1 đề.
class QuestionBankScreen extends StatefulWidget {
  final String examId;
  const QuestionBankScreen({super.key, required this.examId});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final _repo = AdminRepository.instance;
  QaGroup _group = QaGroup.withImage;

  void _openEditor([QaQuestion? q]) => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) =>
                QuestionEditorScreen(examId: widget.examId, question: q)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _repo,
          builder: (context, _) {
            final list = _repo.questionsForExam(widget.examId, _group);
            return Column(
              children: [
                _header(),
                _tabs(),
                _infoStrip(),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Text('Chưa có câu hỏi ở nhóm này',
                              style: AppTextStyles.latin(
                                  size: 13, color: AppColors.textMuted)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 9),
                          itemBuilder: (context, i) => _QuestionCard(
                              question: list[i],
                              index: i + 1,
                              onTap: () => _openEditor(list[i])),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    final total = _repo.questionsForExam(widget.examId).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _iconBtn(Icons.chevron_left, AppColors.border, AppColors.textPrimary,
              () => Navigator.maybePop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8EFFB),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text('Q&A · 45đ',
                      style: AppTextStyles.latin(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.srsMaster)),
                ),
                const SizedBox(height: 3),
                Text('質問リスト · $total câu',
                    style:
                        AppTextStyles.latin(size: 15, weight: FontWeight.w700)),
              ],
            ),
          ),
          _iconBtn(Icons.add, AppColors.srsMaster, Colors.white,
              () => _openEditor()),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final g in QaGroup.values) ...[
            Expanded(child: _tab(g)),
            if (g != QaGroup.values.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _tab(QaGroup g) {
    final selected = g == _group;
    final count = _repo.questionsForExam(widget.examId, g).length;
    return GestureDetector(
      onTap: () => setState(() => _group = g),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.srsMaster : AppColors.border,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text('Nhóm ${g.number} ${g.emoji} ($count)',
            style: AppTextStyles.latin(
                size: 11,
                weight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _infoStrip() {
    final text = switch (_group) {
      QaGroup.withImage =>
        'Nhóm 1 · Câu hỏi có tranh — SV được phát trước mẫu NP + câu hỏi (không có đáp án mẫu)',
      QaGroup.noImage =>
        'Nhóm 2 · Câu hỏi không tranh — SV được phát trước mẫu NP + câu hỏi',
      QaGroup.free => 'Nhóm 3 · Câu hỏi tự do — SV KHÔNG được chuẩn bị trước',
    };
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8EFFB),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(text,
          style: AppTextStyles.latin(
              size: 11,
              weight: FontWeight.w600,
              color: const Color(0xFF2C5FA8),
              height: 1.4)),
    );
  }

  Widget _iconBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: fg, size: 18),
      ),
    );
  }

}

class _QuestionCard extends StatelessWidget {
  final QaQuestion question;
  final int index;
  final VoidCallback? onTap;
  const _QuestionCard(
      {required this.question, required this.index, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: const Color(0xFFE8EFFB),
                    borderRadius: BorderRadius.circular(7)),
                alignment: Alignment.center,
                child: Text('$index',
                    style: AppTextStyles.latin(
                        size: 11,
                        weight: FontWeight.w800,
                        color: AppColors.srsMaster)),
              ),
              const SizedBox(width: 8),
              _chip(question.lesson, const Color(0xFFF5F0FF), AppColors.kanji,
                  jp: true),
              const Spacer(),
              if (question.propType != null)
                _chip(question.propType!, const Color(0xFFFFF1E0),
                    AppColors.listening,
                    jp: true),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F0FF),
                borderRadius: BorderRadius.circular(8)),
            child: Text(question.grammar,
                style: AppTextStyles.jp(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.kanji)),
          ),
          const SizedBox(height: 8),
          Text(question.prompt,
              style: AppTextStyles.jp(
                  size: 14, weight: FontWeight.w500, height: 1.6)),
          if (question.imageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                question.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 48,
                  alignment: Alignment.center,
                  color: AppColors.surfaceAlt,
                  child: Text('Không tải được ảnh',
                      style: AppTextStyles.latin(
                          size: 11, color: AppColors.textMuted)),
                ),
              ),
            ),
          ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg, {bool jp = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: jp
          ? Text(text,
              style: AppTextStyles.jp(
                  size: 10, weight: FontWeight.w700, color: fg))
          : Text(text,
              style: AppTextStyles.latin(
                  size: 10, weight: FontWeight.w700, color: fg)),
    );
  }
}

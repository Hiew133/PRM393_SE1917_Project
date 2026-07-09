import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'data/admin_repository.dart';
import 'models/admin_models.dart';
import 'situation_detail_screen.dart';

/// S03 — Tình huống 会話 của 1 đề (mỗi đề 1 tình huống, dựa 1 mẫu gốc).
class SituationBankScreen extends StatefulWidget {
  final String examId;
  const SituationBankScreen({super.key, required this.examId});

  @override
  State<SituationBankScreen> createState() => _SituationBankScreenState();
}

class _SituationBankScreenState extends State<SituationBankScreen> {
  final _repo = AdminRepository.instance;
  String? _template;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _repo,
          builder: (context, _) {
            final templates = _repo.templatesForExam(widget.examId);
            if (templates.isEmpty) {
              return Column(children: [
                _header(),
                const Expanded(child: Center(child: CircularProgressIndicator())),
              ]);
            }
            final template = templates.contains(_template)
                ? _template!
                : templates.first;
            final variants = _repo.situationsForExam(widget.examId, template);
            return Column(
              children: [
                _header(),
                _templateTabs(templates, template),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      Text('TÌNH HUỐNG · $template',
                          style: AppTextStyles.overline),
                      const SizedBox(height: 10),
                      for (var i = 0; i < variants.length; i++)
                        _SituationCard(situation: variants[i], index: i + 1),
                      const SizedBox(height: 4),
                      _note(),
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

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10)),
              child:
                  const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F0FF),
                    borderRadius: BorderRadius.circular(5)),
                child: Text('会話 · 55đ',
                    style: AppTextStyles.jp(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.kanji)),
              ),
              const SizedBox(height: 3),
              Text('Ngân hàng tình huống',
                  style: AppTextStyles.latin(size: 15, weight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _templateTabs(List<String> templates, String current) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 11, 20, 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3 MẪU GỐC TRONG GIÁO TRÌNH', style: AppTextStyles.overline),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final t in templates) ...[
                Expanded(child: _templateTab(t, current)),
                if (t != templates.last) const SizedBox(width: 7),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _templateTab(String t, String current) {
    final selected = t == current;
    return GestureDetector(
      onTap: () => setState(() => _template = t),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.kanji : AppColors.border,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(t,
            style: AppTextStyles.jp(
                size: 11,
                weight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _note() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F0FF),
          borderRadius: BorderRadius.circular(12)),
      child: Text(
        'Mỗi đề có 1 tình huống 会話. Muốn nhiều biến thể để SV bốc khác nhau '
        '→ tạo thêm đề. Soạn 場面 (vai SV/GV) + 文法 bắt buộc + hội thoại mẫu.',
        style: AppTextStyles.latin(
            size: 11,
            weight: FontWeight.w500,
            color: const Color(0xFF7B3FA8),
            height: 1.4),
      ),
    );
  }
}

class _SituationCard extends StatelessWidget {
  final ConversationSituation situation;
  final int index;
  const _SituationCard({required this.situation, required this.index});

  @override
  Widget build(BuildContext context) {
    final marks = ['①', '②', '③', '④', '⑤'];
    final mark = index <= marks.length ? marks[index - 1] : '$index';
    final drafted = situation.drafted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: drafted ? AppColors.surface : const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SituationDetailScreen(situation: situation))),
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: drafted ? AppColors.border : const Color(0xFFE0C896),
                width: drafted ? 1 : 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                          color: drafted
                              ? const Color(0xFFF5F0FF)
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(7)),
                      alignment: Alignment.center,
                      child: Text(mark,
                          style: AppTextStyles.latin(
                              size: 11,
                              weight: FontWeight.w800,
                              color: drafted
                                  ? AppColors.kanji
                                  : AppColors.textFaint)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(situation.title,
                          style: AppTextStyles.latin(
                              size: 13, weight: FontWeight.w700, height: 1.4)),
                    ),
                    if (drafted)
                      const Icon(Icons.circle, size: 10, color: AppColors.speaking)
                    else
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppColors.brand),
                        child:
                            const Icon(Icons.add, size: 15, color: Colors.white),
                      ),
                  ],
                ),
                if (situation.grammar.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final g in situation.grammar)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF5F0FF),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(g,
                              style: AppTextStyles.jp(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: AppColors.kanji)),
                        ),
                    ],
                  ),
                ],
                if (situation.changeNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFCF6E8),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('Chi tiết đổi: ${situation.changeNote}',
                        style: AppTextStyles.latin(
                            size: 10,
                            weight: FontWeight.w600,
                            color: const Color(0xFF9A6B1E),
                            height: 1.3)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

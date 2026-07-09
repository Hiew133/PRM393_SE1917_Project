import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/admin_repository.dart';
import '../models/admin_models.dart';
import 'situation_editor_screen.dart';

/// S04 — Chi tiết / soạn tình huống (場面 + 文法 + 会話).
class SituationDetailScreen extends StatefulWidget {
  final ConversationSituation situation;
  const SituationDetailScreen({super.key, required this.situation});

  @override
  State<SituationDetailScreen> createState() => _SituationDetailScreenState();
}

class _SituationDetailScreenState extends State<SituationDetailScreen> {
  final _repo = AdminRepository.instance;

  /// Bản mới nhất từ repo (cập nhật sau khi sửa); fallback bản truyền vào.
  ConversationSituation get situation => _repo.situations.firstWhere(
        (s) => s.id == widget.situation.id,
        orElse: () => widget.situation,
      );

  void _openEditor() => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SituationEditorScreen(situation: situation)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _repo,
          builder: (context, _) => Column(
            children: [
              _header(context),
              Expanded(
                child: situation.drafted ? _content() : _emptyState(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F0FF),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text('Tình huống · ${situation.baseTemplate}',
                      style: AppTextStyles.latin(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.kanji)),
                ),
                const SizedBox(height: 3),
                Text('Soạn hội thoại',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyles.latin(size: 15, weight: FontWeight.w700)),
              ],
            ),
          ),
          if (situation.drafted)
            GestureDetector(
              onTap: _openEditor,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.kanji,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 14, color: Colors.white),
                    const SizedBox(width: 5),
                    Text('Sửa',
                        style: AppTextStyles.latin(
                            size: 13,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _label('場面 — SINH VIÊN', 'S', AppColors.kanji),
        const SizedBox(height: 7),
        _scenarioBox(situation.scenarioStudent),
        const SizedBox(height: 14),
        _label('場面 — GIẢNG VIÊN', 'T', AppColors.srsMaster),
        const SizedBox(height: 7),
        _scenarioBox(situation.scenarioTeacher),
        const SizedBox(height: 14),
        Text('文法 BẮT BUỘC', style: AppTextStyles.overline),
        const SizedBox(height: 8),
        for (var i = 0; i < situation.grammar.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _grammarRow(i + 1, situation.grammar[i]),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('会話 MẪU', style: AppTextStyles.overline),
            Row(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFCE8B0),
                      border: Border.all(color: const Color(0xFFE8B84A)),
                      borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 5),
                Text('＿＿ chi tiết có thể đổi',
                    style: AppTextStyles.latin(
                        size: 10,
                        weight: FontWeight.w600,
                        color: const Color(0xFFA8861E))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 9),
        _dialogueCard(),
      ],
    );
  }

  Widget _label(String text, String badge, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: Text(badge,
              style: AppTextStyles.latin(
                  size: 11, weight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 7),
        Text(text, style: AppTextStyles.overline),
      ],
    );
  }

  Widget _scenarioBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEEE9),
        border: Border.all(color: const Color(0xFFF0D5CB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: AppTextStyles.jp(
              size: 13, weight: FontWeight.w400, height: 1.8)),
    );
  }

  Widget _grammarRow(int n, String grammar) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: const Color(0xFFDDD4F5), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text('$n',
              style: AppTextStyles.latin(
                  size: 11, weight: FontWeight.w800, color: AppColors.kanji)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(grammar,
                style: AppTextStyles.jp(size: 14, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _dialogueCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (final line in situation.sample)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _dialogueLine(line),
            ),
        ],
      ),
    );
  }

  Widget _dialogueLine(DialogueLine line) {
    final isStudent = line.role == 'S';
    final color = isStudent ? AppColors.kanji : AppColors.srsMaster;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          alignment: Alignment.center,
          child: Text(line.role,
              style: AppTextStyles.latin(
                  size: 10, weight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(line.text,
              style: AppTextStyles.jp(
                  size: 14,
                  weight: isStudent ? FontWeight.w500 : FontWeight.w400,
                  color: isStudent ? AppColors.kanji : AppColors.textPrimary,
                  height: 1.6)),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FF),
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.edit_note,
                  size: 36, color: AppColors.kanji),
            ),
            const SizedBox(height: 16),
            Text('Biến thể chưa soạn',
                style: AppTextStyles.latin(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Giữ ${situation.grammar.join(" · ")} và bối cảnh chung, '
              'đổi chi tiết để tạo tình huống mới.',
              textAlign: TextAlign.center,
              style: AppTextStyles.latin(
                  size: 12, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _openEditor,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color: AppColors.kanji,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('Bắt đầu soạn',
                    style: AppTextStyles.latin(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'data/admin_repository.dart';
import 'models/admin_models.dart';

/// Soạn / sửa một tình huống 会話 (場面 SV + 場面 GV + 文法 + 会話 mẫu có chỗ
/// trống ＿＿). Lưu Firestore qua [AdminRepository.saveSituation].
class SituationEditorScreen extends StatefulWidget {
  final ConversationSituation situation;
  const SituationEditorScreen({super.key, required this.situation});

  @override
  State<SituationEditorScreen> createState() => _SituationEditorScreenState();
}

class _SituationEditorScreenState extends State<SituationEditorScreen> {
  final _repo = AdminRepository.instance;

  late final TextEditingController _title =
      TextEditingController(text: widget.situation.title);
  late final TextEditingController _changeNote =
      TextEditingController(text: widget.situation.changeNote);
  late final TextEditingController _scStudent =
      TextEditingController(text: widget.situation.scenarioStudent);
  late final TextEditingController _scTeacher =
      TextEditingController(text: widget.situation.scenarioTeacher);

  // 文法 — mỗi mẫu một controller.
  late final List<TextEditingController> _grammar = widget.situation.grammar
      .map((g) => TextEditingController(text: g))
      .toList();

  // 会話 mẫu — mỗi lượt thoại có vai (S/T) + nội dung.
  late final List<_LineDraft> _lines = widget.situation.sample
      .map((l) => _LineDraft(l.role, TextEditingController(text: l.text)))
      .toList();

  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _changeNote.dispose();
    _scStudent.dispose();
    _scTeacher.dispose();
    for (final c in _grammar) {
      c.dispose();
    }
    for (final l in _lines) {
      l.controller.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _title.text.trim().isNotEmpty &&
      _scStudent.text.trim().isNotEmpty &&
      _grammar.any((c) => c.text.trim().isNotEmpty) &&
      _lines.any((l) => l.controller.text.trim().isNotEmpty);

  /// Chèn ＿＿ vào vị trí con trỏ của một controller.
  void _insertBlank(TextEditingController c) {
    final sel = c.selection;
    final text = c.text;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, '＿＿');
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + 2),
    );
    setState(() {});
  }

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final s = widget.situation;
    s.title = _title.text.trim();
    s.changeNote = _changeNote.text.trim();
    s.scenarioStudent = _scStudent.text.trim();
    s.scenarioTeacher = _scTeacher.text.trim();
    s.grammar = _grammar
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    s.sample = _lines
        .where((l) => l.controller.text.trim().isNotEmpty)
        .map((l) => DialogueLine(l.role, l.controller.text.trim()))
        .toList();
    s.drafted = true;
    try {
      await _repo.saveSituation(s);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lưu thất bại: $e')));
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  _label('TÊN TÌNH HUỐNG *'),
                  _field(_title, 'VD: Rủ bạn đi workshop văn hoá'),
                  const SizedBox(height: 16),
                  _label('CHI TIẾT CÓ THỂ ĐỔI'),
                  _field(_changeNote, 'VD: Đổi loại sự kiện / điều kiện'),
                  const SizedBox(height: 16),
                  _scenarioSection(
                      '場面 — SINH VIÊN *', 'S', AppColors.kanji, _scStudent,
                      'Bối cảnh & nhiệm vụ cho SV (tiếng Nhật)'),
                  const SizedBox(height: 16),
                  _scenarioSection('場面 — GIẢNG VIÊN', 'T', AppColors.srsMaster,
                      _scTeacher, 'Bối cảnh cho giảng viên đóng vai'),
                  const SizedBox(height: 18),
                  _grammarSection(),
                  const SizedBox(height: 18),
                  _dialogueSection(),
                ],
              ),
            ),
            _saveBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
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
              child: const Icon(Icons.close,
                  color: AppColors.textPrimary, size: 20),
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
                  child: Text('Tình huống · ${widget.situation.baseTemplate}',
                      style: AppTextStyles.latin(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.kanji)),
                ),
                const SizedBox(height: 3),
                Text(widget.situation.drafted ? 'Sửa hội thoại' : 'Soạn hội thoại',
                    style:
                        AppTextStyles.latin(size: 16, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: AppTextStyles.overline),
      );

  Widget _scenarioSection(String title, String badge, Color color,
      TextEditingController c, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.center,
              child: Text(badge,
                  style: AppTextStyles.latin(
                      size: 11, weight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 7),
            Text(title, style: AppTextStyles.overline),
          ],
        ),
        const SizedBox(height: 8),
        _field(c, hint, jp: true, lines: 4),
      ],
    );
  }

  // ── 文法 ────────────────────────────────────────────────
  Widget _grammarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('文法 BẮT BUỘC *', style: AppTextStyles.overline),
            _addButton('Thêm 文法', () {
              setState(() => _grammar.add(TextEditingController()));
            }),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _grammar.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F0FF),
                      borderRadius: BorderRadius.circular(7)),
                  child: Text('${i + 1}',
                      style: AppTextStyles.latin(
                          size: 11,
                          weight: FontWeight.w800,
                          color: AppColors.kanji)),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: _field(_grammar[i], 'VD: 〜よね', jp: true)),
                _removeButton(() {
                  setState(() {
                    _grammar.removeAt(i).dispose();
                  });
                }),
              ],
            ),
          ),
      ],
    );
  }

  // ── 会話 mẫu ────────────────────────────────────────────
  Widget _dialogueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('会話 MẪU *', style: AppTextStyles.overline),
            _addButton('Thêm lượt', () {
              setState(() => _lines.add(_LineDraft('S', TextEditingController())));
            }),
          ],
        ),
        const SizedBox(height: 4),
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
            Text('Bấm "＿＿" để chèn chỗ trống chi tiết có thể đổi',
                style: AppTextStyles.latin(
                    size: 10,
                    weight: FontWeight.w600,
                    color: const Color(0xFFA8861E))),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _lines.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _lineRow(i),
          ),
      ],
    );
  }

  Widget _lineRow(int i) {
    final line = _lines[i];
    final isStudent = line.role == 'S';
    final color = isStudent ? AppColors.kanji : AppColors.srsMaster;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(
                    () => line.role = isStudent ? 'T' : 'S'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Text(isStudent ? 'S · Sinh viên' : 'T · Giảng viên',
                          style: AppTextStyles.latin(
                              size: 11,
                              weight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(width: 4),
                      const Icon(Icons.swap_horiz,
                          size: 13, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _insertBlank(line.controller),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFCF6E8),
                      border: Border.all(color: const Color(0xFFE8B84A)),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('＿＿',
                      style: AppTextStyles.jp(
                          size: 12,
                          weight: FontWeight.w800,
                          color: const Color(0xFFA8861E))),
                ),
              ),
              const SizedBox(width: 6),
              _removeButton(() {
                setState(() {
                  _lines.removeAt(i).controller.dispose();
                });
              }),
            ],
          ),
          const SizedBox(height: 8),
          _field(line.controller, 'Nội dung lượt thoại (tiếng Nhật)',
              jp: true, lines: 2),
        ],
      ),
    );
  }

  // ── Widget chung ────────────────────────────────────────
  Widget _field(TextEditingController c, String hint,
      {bool jp = false, int lines = 1}) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      maxLines: lines,
      minLines: 1,
      style: jp
          ? AppTextStyles.jp(size: 15, weight: FontWeight.w500, height: 1.6)
          : AppTextStyles.latin(size: 15, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.jp(size: 13, color: AppColors.textFaint),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kanji, width: 1.5),
        ),
      ),
    );
  }

  Widget _addButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: const Color(0xFFF5F0FF),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.add, size: 14, color: AppColors.kanji),
            const SizedBox(width: 3),
            Text(text,
                style: AppTextStyles.latin(
                    size: 11, weight: FontWeight.w700, color: AppColors.kanji)),
          ],
        ),
      ),
    );
  }

  Widget _removeButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(Icons.remove_circle_outline,
            size: 22, color: AppColors.vocab.withValues(alpha: 0.8)),
      ),
    );
  }

  Widget _saveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: GestureDetector(
        onTap: _save,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _valid ? AppColors.kanji : AppColors.border,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(_saving ? 'Đang lưu...' : 'Lưu tình huống',
              style: AppTextStyles.latin(
                  size: 15,
                  weight: FontWeight.w700,
                  color: _valid ? Colors.white : AppColors.textFaint)),
        ),
      ),
    );
  }
}

/// Bản nháp một lượt thoại trong editor.
class _LineDraft {
  String role; // 'S' | 'T'
  final TextEditingController controller;
  _LineDraft(this.role, this.controller);
}

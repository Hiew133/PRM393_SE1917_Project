import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../speaking/models/nihon1_exam_sets.dart';
import 'data/admin_repository.dart';

/// Soạn / sửa một đề thi Nhật 1 (JPD113): bài đọc + tranh + 3 câu theo tranh +
/// 1 câu tự do. Đề đã được tạo sẵn (list screen gọi createNihon1Exam trước),
/// nên màn này luôn nhận [exam] khác null.
class Nihon1ExamEditorScreen extends StatefulWidget {
  final Nihon1Exam exam;
  const Nihon1ExamEditorScreen({super.key, required this.exam});

  @override
  State<Nihon1ExamEditorScreen> createState() => _Nihon1ExamEditorScreenState();
}

class _Nihon1ExamEditorScreenState extends State<Nihon1ExamEditorScreen> {
  final _repo = AdminRepository.instance;

  late final _title = TextEditingController(text: widget.exam.title);
  late final _passage = TextEditingController(text: widget.exam.passage);
  late final _passageVi = TextEditingController(text: widget.exam.passageVi);
  late final _emoji = TextEditingController(text: widget.exam.pictureEmoji);
  late final _caption = TextEditingController(text: widget.exam.pictureCaption);
  late final _free = TextEditingController(text: widget.exam.freeQuestion);

  // Danh sách gợi ý trên tranh — thêm/xoá được.
  late final List<TextEditingController> _hints = [
    for (final h in widget.exam.pictureHints) TextEditingController(text: h),
  ];
  // Đúng 3 câu hỏi theo tranh (pad nếu đề cũ thiếu).
  late final List<TextEditingController> _pq = [
    for (var i = 0; i < 3; i++)
      TextEditingController(
        text: i < widget.exam.pictureQuestions.length
            ? widget.exam.pictureQuestions[i]
            : '',
      ),
  ];

  late bool _published = widget.exam.published;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _passage, _passageVi, _emoji, _caption, _free]) {
      c.dispose();
    }
    for (final c in _hints) {
      c.dispose();
    }
    for (final c in _pq) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _title.text.trim().isNotEmpty && _passage.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final e = widget.exam
      ..title = _title.text.trim()
      ..passage = _passage.text.trim()
      ..passageVi = _passageVi.text.trim()
      ..pictureEmoji =
          _emoji.text.trim().isEmpty ? '🖼️' : _emoji.text.trim()
      ..pictureCaption = _caption.text.trim()
      ..pictureHints = [
        for (final c in _hints)
          if (c.text.trim().isNotEmpty) c.text.trim()
      ]
      ..pictureQuestions = [for (final c in _pq) c.text.trim()]
      ..freeQuestion = _free.text.trim()
      ..published = _published;
    try {
      await _repo.saveNihon1Exam(e);
    } catch (err) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lưu thất bại: $err')));
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá đề này?'),
        content: const Text('Xoá vĩnh viễn đề Nhật 1 này. Không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Xoá', style: TextStyle(color: AppColors.vocab))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _repo.deleteNihon1Exam(widget.exam);
      if (mounted) Navigator.of(context).pop();
    }
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
                  _publishRow(),
                  const SizedBox(height: 16),
                  _label('TIÊU ĐỀ ĐỀ *'),
                  _field(_title, 'VD: Đề 6 · Đọc: … — Tranh: …'),
                  const SizedBox(height: 18),
                  _sectionHead('📖', 'BÀI ĐỌC (30đ) — SV đọc to'),
                  const SizedBox(height: 8),
                  _label('ĐOẠN VĂN TIẾNG NHẬT *'),
                  _field(_passage, 'たなかさんは 日本語の学生です。…',
                      jp: true, lines: 5),
                  const SizedBox(height: 12),
                  _label('DỊCH TIẾNG VIỆT (hiện kèm cho SV)'),
                  _field(_passageVi, 'Anh Tanaka là sinh viên tiếng Nhật. …',
                      lines: 3),
                  const SizedBox(height: 18),
                  _sectionHead('🖼️', 'TRANH — 3 câu hỏi theo tranh'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 76,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('EMOJI'),
                            _field(_emoji, '👨🏽‍💼', center: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('NHÃN TRANH (caption)'),
                            _field(_caption, 'VD: アリさん', jp: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _label('GỢI Ý TRÊN TRANH (mỗi dòng 1 thông tin)'),
                  _hintsEditor(),
                  const SizedBox(height: 12),
                  _label('3 CÂU HỎI THEO TRANH (đúng thứ tự)'),
                  for (var i = 0; i < _pq.length; i++) ...[
                    _pqField(i),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 10),
                  _sectionHead('💬', 'CÂU HỎI TỰ DO (câu cuối)'),
                  const SizedBox(height: 8),
                  _field(_free, 'VD: まいにち、なにを しますか。', jp: true, lines: 2),
                  const SizedBox(height: 24),
                  _deleteButton(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Soạn đề Nhật 1',
                  style: AppTextStyles.latin(size: 16, weight: FontWeight.w700)),
              Text('JPD113 · đọc 30đ + 4 câu 60đ + tác phong 10đ',
                  style:
                      AppTextStyles.latin(size: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _publishRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _published ? const Color(0xFFEFF8F2) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _published
                ? AppColors.speaking.withValues(alpha: 0.4)
                : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_published ? Icons.public : Icons.edit_note,
              size: 18,
              color: _published ? AppColors.speaking : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                _published
                    ? 'Đã xuất bản — học viên bốc được'
                    : 'Nháp — học viên chưa thấy',
                style:
                    AppTextStyles.latin(size: 13, weight: FontWeight.w600)),
          ),
          Switch(
            value: _published,
            activeTrackColor: AppColors.speaking,
            onChanged: (v) => setState(() => _published = v),
          ),
        ],
      ),
    );
  }

  Widget _sectionHead(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 7),
        Text(text,
            style: AppTextStyles.latin(
                size: 13, weight: FontWeight.w800, color: AppColors.speaking)),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: AppTextStyles.overline),
      );

  Widget _hintsEditor() {
    return Column(
      children: [
        for (var i = 0; i < _hints.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _field(_hints[i], 'VD: しごと：ぎんこういん', jp: true),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() {
                    _hints.removeAt(i).dispose();
                  }),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.remove,
                        size: 18, color: AppColors.vocab),
                  ),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: () => setState(() => _hints.add(TextEditingController())),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.speaking.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 17, color: AppColors.speaking),
                const SizedBox(width: 6),
                Text('Thêm gợi ý',
                    style: AppTextStyles.latin(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.speaking)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pqField(int i) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AppColors.speaking.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Text('${i + 1}',
              style: AppTextStyles.latin(
                  size: 12,
                  weight: FontWeight.w800,
                  color: AppColors.speaking)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _field(_pq[i], 'VD: この ひとの なまえは なんですか。',
              jp: true),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String hint,
      {bool jp = false, int lines = 1, bool center = false}) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      maxLines: lines,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: jp
          ? AppTextStyles.jp(size: 15, weight: FontWeight.w500)
          : AppTextStyles.latin(size: 15, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.jp(size: 12.5, color: AppColors.textFaint),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.speaking, width: 1.5),
        ),
      ),
    );
  }

  Widget _deleteButton() {
    return GestureDetector(
      onTap: _delete,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline, size: 18, color: AppColors.vocab),
            const SizedBox(width: 7),
            Text('Xoá đề này',
                style: AppTextStyles.latin(
                    size: 14, weight: FontWeight.w700, color: AppColors.vocab)),
          ],
        ),
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
            color: _valid ? AppColors.speaking : AppColors.border,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(_saving ? 'Đang lưu...' : 'Lưu đề',
              style: AppTextStyles.latin(
                  size: 15,
                  weight: FontWeight.w700,
                  color: _valid ? Colors.white : AppColors.textFaint)),
        ),
      ),
    );
  }
}

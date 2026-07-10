import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../speaking/models/nihon2_exam_sets.dart';
import 'data/admin_repository.dart';

/// Soạn / sửa một đề thi Nhật 2 (JPD123): bài đọc (45đ) + tranh + 1 câu theo
/// tranh + 2 câu không tranh (3×15đ). Form GIỐNG đề Nhật 1, chỉ khác cơ cấu
/// câu hỏi. Đề đã được tạo sẵn (list screen gọi createNihon2Exam trước).
class Nihon2ExamEditorScreen extends StatefulWidget {
  final Nihon2Exam exam;
  const Nihon2ExamEditorScreen({super.key, required this.exam});

  @override
  State<Nihon2ExamEditorScreen> createState() => _Nihon2ExamEditorScreenState();
}

class _Nihon2ExamEditorScreenState extends State<Nihon2ExamEditorScreen> {
  final _repo = AdminRepository.instance;

  late final _title = TextEditingController(text: widget.exam.title);
  late final _passage = TextEditingController(text: widget.exam.passage);
  late final _passageVi = TextEditingController(text: widget.exam.passageVi);
  late final _emoji = TextEditingController(text: widget.exam.pictureEmoji);
  late final _caption = TextEditingController(text: widget.exam.pictureCaption);
  late final _q1 = TextEditingController(text: widget.exam.pictureQuestion);
  late final _q2 = TextEditingController(text: widget.exam.question2);
  late final _q3 = TextEditingController(text: widget.exam.question3);

  // Danh sách gợi ý trên tranh — thêm/xoá được.
  late final List<TextEditingController> _hints = [
    for (final h in widget.exam.pictureHints) TextEditingController(text: h),
  ];

  late bool _published = widget.exam.published;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _passage, _passageVi, _emoji, _caption, _q1, _q2, _q3]) {
      c.dispose();
    }
    for (final c in _hints) {
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
      ..pictureEmoji = _emoji.text.trim().isEmpty ? '🖼️' : _emoji.text.trim()
      ..pictureCaption = _caption.text.trim()
      ..pictureHints = [
        for (final c in _hints)
          if (c.text.trim().isNotEmpty) c.text.trim()
      ]
      ..pictureQuestion = _q1.text.trim()
      ..question2 = _q2.text.trim()
      ..question3 = _q3.text.trim()
      ..published = _published;
    try {
      await _repo.saveNihon2Exam(e);
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
        content: const Text('Xoá vĩnh viễn đề Nhật 2 này. Không thể hoàn tác.'),
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
      await _repo.deleteNihon2Exam(widget.exam);
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
                  _field(_title, 'VD: Đề 4 · Đọc: … — Tranh: …'),
                  const SizedBox(height: 18),
                  _sectionHead('📖', 'BÀI ĐỌC (45đ) — SV đọc to'),
                  const SizedBox(height: 4),
                  Text(
                      'Khoảng 150 chữ; ngoài hiragana nên có 5–7 kanji và '
                      '2–4 từ katakana (theo HD thi JPD123).',
                      style: AppTextStyles.latin(
                          size: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  _label('ĐOẠN VĂN TIẾNG NHẬT *'),
                  _field(_passage, 'わたしは　今年の８月に　ベトナムへ　行きました。…',
                      jp: true, lines: 6),
                  const SizedBox(height: 12),
                  _label('DỊCH TIẾNG VIỆT (hiện kèm cho SV)'),
                  _field(_passageVi, 'Tôi đã đến Việt Nam vào tháng 8 năm nay. …',
                      lines: 3),
                  const SizedBox(height: 18),
                  _sectionHead('🖼️', 'TRANH — cho câu hỏi ①'),
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
                            _field(_emoji, '✈️', center: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('NHÃN TRANH (caption)'),
                            _field(_caption, 'VD: ハノイ → ホーチミン', jp: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _label('GỢI Ý TRÊN TRANH (mỗi dòng 1 thông tin)'),
                  _hintsEditor(),
                  const SizedBox(height: 16),
                  _sectionHead('💬', '3 CÂU HỎI (mỗi câu 15đ)'),
                  const SizedBox(height: 8),
                  _label('CÂU ① — THEO TRANH'),
                  _field(_q1, 'VD: ハノイから　ホーチミンまで　どのくらいですか。',
                      jp: true, lines: 2),
                  const SizedBox(height: 12),
                  _label('CÂU ② — KHÔNG TRANH'),
                  _field(_q2, 'VD: 今、何が　ほしいですか。', jp: true, lines: 2),
                  const SizedBox(height: 12),
                  _label('CÂU ③ — KHÔNG TRANH'),
                  _field(_q3, 'VD: 春と　夏と　どちらが　好きですか。',
                      jp: true, lines: 2),
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
              Text('Soạn đề Nhật 2',
                  style: AppTextStyles.latin(size: 16, weight: FontWeight.w700)),
              Text('JPD123 · đọc 45đ + 3 câu 45đ + tác phong 10đ',
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
                  child: _field(_hints[i], 'VD: ひこうき ✈️ · ２じかんはん',
                      jp: true),
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

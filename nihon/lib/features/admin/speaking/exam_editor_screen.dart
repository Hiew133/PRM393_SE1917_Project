import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'data/admin_repository.dart';
import 'models/admin_models.dart';

/// Soạn đề mới hoặc sửa thông tin đề. Truyền [exam] = null để tạo mới.
class ExamEditorScreen extends StatefulWidget {
  final Exam? exam;
  const ExamEditorScreen({super.key, this.exam});

  bool get isEdit => exam != null;

  @override
  State<ExamEditorScreen> createState() => _ExamEditorScreenState();
}

class _ExamEditorScreenState extends State<ExamEditorScreen> {
  final _repo = AdminRepository.instance;
  late final TextEditingController _title =
      TextEditingController(text: widget.exam?.title ?? '');
  late final TextEditingController _lesson =
      TextEditingController(text: widget.exam?.lessonRange ?? 'Bài 1~5');
  late ExamStatus _status = widget.exam?.status ?? ExamStatus.draft;

  @override
  void dispose() {
    _title.dispose();
    _lesson.dispose();
    super.dispose();
  }

  bool get _valid => _title.text.trim().isNotEmpty;

  bool _saving = false;

  Future<void> _save() async {
    if (!_valid || _saving) {
      if (!_valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hãy nhập tên đề thi')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.isEdit) {
        await _repo.saveExam(widget.exam!,
            title: _title.text, lessonRange: _lesson.text, status: _status);
      } else {
        final exam =
            await _repo.createExam(title: _title.text, lessonRange: _lesson.text);
        if (_status != ExamStatus.draft) {
          await _repo.updateExamStatus(exam, _status);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu thất bại: $e')),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.isEdit ? 'Đã lưu đề' : 'Đã tạo đề mới')),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá đề thi?'),
        content: Text('Xoá "${widget.exam!.title}"? Không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: AppColors.vocab)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _repo.deleteExam(widget.exam!);
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                children: [
                  _fieldLabel('TÊN ĐỀ THI *'),
                  _textField(_title, 'VD: Thi cuối kỳ JPD316 — Đề C'),
                  const SizedBox(height: 18),
                  _fieldLabel('PHẠM VI BÀI'),
                  _textField(_lesson, 'VD: Bài 1~5'),
                  const SizedBox(height: 18),
                  _fieldLabel('TRẠNG THÁI'),
                  _statusPicker(),
                  const SizedBox(height: 18),
                  _structureNote(),
                  if (widget.isEdit) ...[
                    const SizedBox(height: 24),
                    _deleteButton(),
                  ],
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
              child: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Text(widget.isEdit ? 'Sửa thông tin đề' : 'Tạo đề mới',
              style: AppTextStyles.latin(size: 16, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTextStyles.overline),
      );

  Widget _textField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      style: AppTextStyles.latin(size: 15, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.latin(size: 14, color: AppColors.textFaint),
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

  Widget _statusPicker() {
    return Row(
      children: [
        for (final s in ExamStatus.values) ...[
          Expanded(child: _statusOption(s)),
          if (s != ExamStatus.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _statusOption(ExamStatus s) {
    final selected = s == _status;
    final color = switch (s) {
      ExamStatus.published => AppColors.speaking,
      ExamStatus.draft => AppColors.listening,
      ExamStatus.archived => AppColors.textMuted,
    };
    return GestureDetector(
      onTap: () => setState(() => _status = s),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(s.label,
            style: AppTextStyles.latin(
                size: 13,
                weight: FontWeight.w700,
                color: selected ? color : AppColors.textSecondary)),
      ),
    );
  }

  Widget _structureNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F0FF),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.kanji),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Cấu trúc chuẩn JPD316 (会話 55đ + Q&A 45đ) áp dụng sẵn. '
              'Soạn tình huống & câu hỏi trong màn cấu trúc đề.',
              style: AppTextStyles.latin(
                  size: 11,
                  weight: FontWeight.w500,
                  color: const Color(0xFF7B3FA8),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deleteButton() {
    return GestureDetector(
      onTap: _confirmDelete,
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
            Text('Xoá đề thi',
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
          child: Text(
              _saving
                  ? 'Đang lưu...'
                  : (widget.isEdit ? 'Lưu thay đổi' : 'Tạo đề'),
              style: AppTextStyles.latin(
                  size: 15,
                  weight: FontWeight.w700,
                  color: _valid ? Colors.white : AppColors.textFaint)),
        ),
      ),
    );
  }
}

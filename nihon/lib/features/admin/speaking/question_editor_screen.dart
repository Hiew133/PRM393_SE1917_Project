import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'data/admin_repository.dart';
import 'models/admin_models.dart';

/// Soạn / sửa một câu hỏi Q&A của một đề. [question] = null để thêm mới.
class QuestionEditorScreen extends StatefulWidget {
  final String examId;
  final QaQuestion? question;
  const QuestionEditorScreen({super.key, required this.examId, this.question});

  bool get isEdit => question != null;

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final _repo = AdminRepository.instance;
  // Id cố định ngay từ đầu để ảnh upload có đường dẫn ổn định (kể cả câu mới).
  late final String _questionId;
  late QaGroup _group = widget.question?.group ?? QaGroup.withImage;
  String? _imageUrl;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _questionId = widget.question?.id ?? _repo.newQuestionId(widget.examId);
    _imageUrl = widget.question?.imageUrl;
  }
  late final TextEditingController _lesson =
      TextEditingController(text: widget.question?.lesson ?? '課1');
  late final TextEditingController _grammar =
      TextEditingController(text: widget.question?.grammar ?? '');
  late final TextEditingController _prompt =
      TextEditingController(text: widget.question?.prompt ?? '');
  late final TextEditingController _prop =
      TextEditingController(text: widget.question?.propType ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _lesson.dispose();
    _grammar.dispose();
    _prompt.dispose();
    _prop.dispose();
    super.dispose();
  }

  bool get _valid =>
      _grammar.text.trim().isNotEmpty && _prompt.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final prop = _prop.text.trim().isEmpty ? null : _prop.text.trim();
    final q = QaQuestion(
      id: _questionId,
      examId: widget.examId,
      order: widget.question?.order ?? _repo.nextQuestionOrder(widget.examId),
      group: _group,
      lesson: _lesson.text.trim(),
      grammar: _grammar.text.trim(),
      prompt: _prompt.text.trim(),
      propType: _group == QaGroup.withImage ? prop : null,
      imageUrl: _group == QaGroup.withImage ? _imageUrl : null,
    );
    try {
      await _repo.saveQuestion(q);
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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá câu hỏi?'),
        content: const Text('Không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá',
                  style: TextStyle(color: AppColors.vocab))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _repo.deleteQuestion(widget.question!);
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
                  _label('NHÓM CÂU HỎI'),
                  _groupPicker(),
                  const SizedBox(height: 16),
                  _label('課 (BÀI)'),
                  _field(_lesson, 'VD: 課1', jp: true),
                  const SizedBox(height: 16),
                  _label('文法 — NGỮ PHÁP MUỐN KHAI THÁC *'),
                  _field(_grammar, 'VD: 〜において／〜における', jp: true),
                  const SizedBox(height: 16),
                  _label('質問 — CÂU HỎI *'),
                  _field(_prompt, '（新聞記事を見せる）何が書いてありますか。',
                      jp: true, lines: 3),
                  if (_group == QaGroup.withImage) ...[
                    const SizedBox(height: 16),
                    _label('NGỮ LIỆU / TRANH (tuỳ chọn)'),
                    _field(_prop, 'VD: 新聞記事 / 天気予報 / チラシ / イラスト',
                        jp: true),
                    const SizedBox(height: 16),
                    _label('ẢNH TRANH (SV nhìn để trả lời)'),
                    _imageSection(),
                  ],
                  if (widget.isEdit) ...[
                    const SizedBox(height: 22),
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
              child:
                  const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Text(widget.isEdit ? 'Sửa câu hỏi' : 'Thêm câu hỏi',
              style: AppTextStyles.latin(size: 16, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: AppTextStyles.overline),
      );

  Widget _groupPicker() {
    return Row(
      children: [
        for (final g in QaGroup.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _group = g),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: g == _group
                      ? AppColors.srsMaster
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: g == _group ? AppColors.srsMaster : AppColors.border),
                ),
                child: Text('${g.number} ${g.emoji}',
                    style: AppTextStyles.latin(
                        size: 12,
                        weight: FontWeight.w700,
                        color:
                            g == _group ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          ),
          if (g != QaGroup.values.last) const SizedBox(width: 7),
        ],
      ],
    );
  }

  Widget _field(TextEditingController c, String hint,
      {bool jp = false, int lines = 1}) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      maxLines: lines,
      style: jp
          ? AppTextStyles.jp(size: 15, weight: FontWeight.w500)
          : AppTextStyles.latin(size: 15, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.jp(size: 13, color: AppColors.textFaint),
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
          borderSide: const BorderSide(color: AppColors.srsMaster, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_uploadingImage) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _uploadingImage = true);
      final url =
          await _repo.uploadQaImage(widget.examId, _questionId, bytes);
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _uploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tải ảnh thất bại: $e. '
              'Kiểm tra đã bật Firebase Storage chưa.')));
    }
  }

  Widget _imageSection() {
    if (_uploadingImage) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(height: 10),
            Text('Đang tải ảnh lên…'),
          ],
        ),
      );
    }
    if (_imageUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _imageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 180,
                alignment: Alignment.center,
                color: AppColors.surfaceAlt,
                child: const Text('Không tải được ảnh'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Đổi ảnh'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => setState(() => _imageUrl = null),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.vocab),
                label: const Text('Gỡ',
                    style: TextStyle(color: AppColors.vocab)),
              ),
            ],
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EFFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.srsMaster.withValues(alpha: 0.5),
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                size: 30, color: AppColors.srsMaster),
            const SizedBox(height: 8),
            Text('Chọn ảnh từ máy',
                style: AppTextStyles.latin(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.srsMaster)),
          ],
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
            Text('Xoá câu hỏi',
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
            color: _valid ? AppColors.srsMaster : AppColors.border,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(_saving ? 'Đang lưu...' : 'Lưu câu hỏi',
              style: AppTextStyles.latin(
                  size: 15,
                  weight: FontWeight.w700,
                  color: _valid ? Colors.white : AppColors.textFaint)),
        ),
      ),
    );
  }
}

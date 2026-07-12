import 'package:flutter/material.dart';

import '../../core/services/speech_assessment_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AdminAISettingsScreen extends StatefulWidget {
  const AdminAISettingsScreen({super.key});

  @override
  State<AdminAISettingsScreen> createState() => _AdminAISettingsScreenState();
}

class _AdminAISettingsScreenState extends State<AdminAISettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final SpeechAssessmentService _service = SpeechAssessmentService();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = _service.apiKey ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _apiKeyController.text.trim();
    await _service.setApiKey(key.isEmpty ? null : key);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          key.isEmpty
              ? 'Đã xóa Gemini API Key. AI sẽ tạm tắt.'
              : 'Đã lưu Gemini API Key cho các tính năng AI.',
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _clear() async {
    _apiKeyController.clear();
    await _service.setApiKey(null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa Gemini API Key.')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = (_service.apiKey ?? '').trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.brand.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                hasKey
                                    ? Icons.check_circle_rounded
                                    : Icons.key_off_rounded,
                                color: hasKey
                                    ? AppColors.speaking
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasKey ? 'AI đang bật' : 'AI chưa có key',
                                    style: AppTextStyles.latin(
                                      size: 16,
                                      weight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Dùng cho Trợ lý AI, mẹo nhớ Kanji và chấm phát âm Gemini.',
                                    style: AppTextStyles.latin(
                                      size: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _apiKeyController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Gemini API Key',
                            hintText: 'Dán API key tại đây',
                            prefixIcon: const Icon(Icons.key_rounded),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceAlt,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Key được lưu cục bộ trên thiết bị này. Không commit key vào source code.',
                          style: AppTextStyles.latin(
                            size: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Lưu API Key'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Xóa key'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: AppColors.vocab,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Cấu hình AI',
                      style: AppTextStyles.latin(
                        size: 20,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.psychology_rounded,
                      color: AppColors.brand,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Gemini API Key cho Nihon AI',
                  style: AppTextStyles.latin(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

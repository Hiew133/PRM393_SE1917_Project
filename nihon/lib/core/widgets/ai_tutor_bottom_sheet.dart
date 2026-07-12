import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AITutorBottomSheet extends StatefulWidget {
  final String topic;
  final String type; // 'kanji' or 'grammar'

  const AITutorBottomSheet({
    super.key,
    required this.topic,
    required this.type,
  });

  static void show(BuildContext context, {required String topic, required String type}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AITutorBottomSheet(topic: topic, type: type),
    );
  }

  @override
  State<AITutorBottomSheet> createState() => _AITutorBottomSheetState();
}

class _AITutorBottomSheetState extends State<AITutorBottomSheet> {
  String _response = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAIExplanation();
  }

  Future<void> _loadAIExplanation() async {
    setState(() {
      _isLoading = true;
      _response = '';
    });

    final explanation = await AIService().askTutor(
      topic: widget.topic,
      type: widget.type,
    );

    if (mounted) {
      setState(() {
        _response = explanation;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'kanji' ? 'Giải nghĩa chữ Kanji: ${widget.topic}' : 'Giải nghĩa Ngữ pháp: ${widget.topic}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF), // Soft blue tint
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.latin(
                          size: 16,
                          color: AppColors.textPrimary,
                          weight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trợ lý học tập AI - Gemini 2.5 Flash',
                        style: AppTextStyles.latin(
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  onPressed: _isLoading ? null : _loadAIExplanation,
                  tooltip: 'Hỏi lại',
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildResponseContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.kanji,
              strokeWidth: 3.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Trợ lý AI đang nghiên cứu tài liệu...',
            style: AppTextStyles.latin(
              size: 14,
              color: AppColors.textSecondary,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quá trình này có thể mất vài giây',
            style: AppTextStyles.latin(
              size: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseContent() {
    final lines = _response.split('\n');
    final List<Widget> widgets = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Check if header
      if (trimmed.startsWith('###')) {
        final text = trimmed.substring(3).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            text,
            style: AppTextStyles.latin(
              size: 14,
              color: AppColors.textPrimary,
              weight: FontWeight.bold,
            ),
          ),
        ));
      } else if (trimmed.startsWith('##')) {
        final text = trimmed.substring(2).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(
            text,
            style: AppTextStyles.latin(
              size: 16,
              color: AppColors.kanji,
              weight: FontWeight.bold,
            ),
          ),
        ));
      } else if (trimmed.startsWith('#')) {
        final text = trimmed.substring(1).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            text,
            style: AppTextStyles.latin(
              size: 18,
              color: AppColors.kanji,
              weight: FontWeight.bold,
            ),
          ),
        ));
      } else if (trimmed.startsWith('*') || trimmed.startsWith('-')) {
        // Bullet points
        final text = trimmed.substring(1).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 8),
                child: Icon(Icons.circle, size: 6, color: AppColors.kanji),
              ),
              Expanded(
                child: SelectableText(
                  text,
                  style: AppTextStyles.latin(
                    size: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ));
      } else {
        // Regular text
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SelectableText(
            trimmed,
            style: AppTextStyles.latin(
              size: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}

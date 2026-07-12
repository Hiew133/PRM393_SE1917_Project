import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/tts_helper.dart';
import '../../../core/services/speech_assessment_service.dart';

class SpeechAssessmentDialog extends StatefulWidget {
  final String targetText;
  final String furigana;
  final String romaji;
  final String meaning;

  const SpeechAssessmentDialog({
    super.key,
    required this.targetText,
    this.furigana = '',
    this.romaji = '',
    this.meaning = '',
  });

  static void show(
    BuildContext context, {
    required String targetText,
    String furigana = '',
    String romaji = '',
    String meaning = '',
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SpeechAssessment',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: SpeechAssessmentDialog(
            targetText: targetText,
            furigana: furigana,
            romaji: romaji,
            meaning: meaning,
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final scale = 0.85 + (0.15 * anim1.value);
        final opacity = anim1.value;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<SpeechAssessmentDialog> createState() => _SpeechAssessmentDialogState();
}

class _SpeechAssessmentDialogState extends State<SpeechAssessmentDialog> with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final SpeechAssessmentService _assessmentService = SpeechAssessmentService();

  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedWords = '';
  String _statusMessage = 'Nhấn Micro để bắt đầu nói';
  
  SpeechAssessmentResult? _result;
  bool _isAnalyzing = false;
  bool _showApiKeyInput = false;
  final TextEditingController _apiKeyController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _scoreRingController;
  
  // Sóng âm giả lập khi đang nghe
  final List<double> _waveHeights = List.filled(6, 4.0);
  Timer? _waveTimer;

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = _assessmentService.apiKey ?? '';
    
    // Animation cho nút micro
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Animation cho vòng tròn điểm số
    _scoreRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scoreRingController.dispose();
    _waveTimer?.cancel();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_isListening) {
              _stopListeningAndAnalyze();
            }
          }
        },
        onError: (error) {
          print("SpeechToText Error: $error");
          setState(() {
            _statusMessage = 'Không thể mở Micro. Vui lòng kiểm tra quyền truy cập!';
            _isListening = false;
            _pulseController.stop();
            _waveTimer?.cancel();
          });
        },
      );
      setState(() {
        _isInitialized = available;
        if (!available) {
          _statusMessage = 'Tính năng nhận diện giọng nói không khả dụng trên trình duyệt/thiết bị này.';
        }
      });
    } catch (e) {
      setState(() {
        _isInitialized = false;
        _statusMessage = 'Lỗi kết nối bộ thu âm giọng nói.';
      });
    }
  }

  void _startListening() async {
    if (!_isInitialized) {
      await _initSpeech();
      if (!_isInitialized) return;
    }

    setState(() {
      _isListening = true;
      _recognizedWords = '';
      _result = null;
      _statusMessage = 'Đang nghe... Hãy nói bằng Tiếng Nhật';
    });

    _pulseController.repeat(reverse: true);
    
    // Bắt đầu hiệu ứng sóng âm nhấp nhô
    _waveTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      final rand = math.Random();
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 4.0 + rand.nextDouble() * 32.0;
        }
      });
    });

    await _speech.listen(
      localeId: 'ja-JP', // Bắt buộc nhận diện tiếng Nhật
      onResult: (result) {
        setState(() {
          _recognizedWords = result.recognizedWords;
          _statusMessage = 'Đã nhận diện: $_recognizedWords';
        });
      },
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListeningAndAnalyze() async {
    await _speech.stop();
    _pulseController.stop();
    _pulseController.reset();
    _waveTimer?.cancel();
    
    setState(() {
      _isListening = false;
      _waveHeights.fillRange(0, _waveHeights.length, 4.0);
      _isAnalyzing = true;
      _statusMessage = 'Đang phân tích phát âm...';
    });

    // Gọi service chấm điểm phát âm (AI hoặc Local)
    final evaluation = await _assessmentService.assessSpeech(
      target: widget.targetText,
      transcript: _recognizedWords,
      furigana: widget.furigana,
      romaji: widget.romaji,
    );

    setState(() {
      _result = evaluation;
      _isAnalyzing = false;
      _statusMessage = evaluation.isMatch 
          ? 'Phát âm Khớp thành công! 🎉'
          : 'Phát âm chưa chuẩn, vui lòng thử lại.';
    });

    // Kích hoạt vòng tròn điểm
    _scoreRingController.reset();
    _scoreRingController.forward();
  }

  void _saveApiKey() {
    final key = _apiKeyController.text.trim();
    await _assessmentService.setApiKey(key.isNotEmpty ? key : null);
    setState(() {
      _showApiKeyInput = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(key.isNotEmpty ? 'Đã kích hoạt AI Gemini chấm điểm phát âm!' : 'Đã chuyển về bộ chấm điểm tiêu chuẩn.'),
        backgroundColor: AppColors.brandDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = _assessmentService.apiKey != null && _assessmentService.apiKey!.isNotEmpty;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: math.min(MediaQuery.of(context).size.width, 420),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppColors.surfaceAlt,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded, color: AppColors.brandDark, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Đánh giá phát âm AI',
                        style: AppTextStyles.latin(size: 14, weight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Nút cấu hình API Key
                      IconButton(
                        icon: Icon(
                          Icons.psychology_outlined,
                          color: hasKey ? AppColors.kanji : AppColors.textMuted,
                          size: 20,
                        ),
                        tooltip: 'Cài đặt Gemini AI API Key',
                        onPressed: () {
                          setState(() {
                            _showApiKeyInput = !_showApiKeyInput;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_showApiKeyInput)
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF0FDF4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nhập Gemini API Key để mở khóa AI chấm điểm chi tiết (không bắt buộc):',
                      style: AppTextStyles.latin(size: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _apiKeyController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'AI API Key...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kanji,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: _saveApiKey,
                          child: const Text('Lưu', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mục tiêu từ mẫu
                  Center(
                    child: Column(
                      children: [
                        if (widget.furigana.isNotEmpty)
                          Text(
                            widget.furigana,
                            style: AppTextStyles.jp(size: 15, color: AppColors.textMuted),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.targetText,
                              style: AppTextStyles.jp(size: 36, color: AppColors.textPrimary, weight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surfaceAlt,
                                padding: const EdgeInsets.all(6),
                              ),
                              icon: const Icon(Icons.volume_up_rounded, color: AppColors.brandDark, size: 18),
                              onPressed: () => speakJapanese(widget.targetText),
                            ),
                          ],
                        ),
                        if (widget.romaji.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.romaji,
                            style: AppTextStyles.latin(size: 12, color: AppColors.textFaint).copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                        if (widget.meaning.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Nghĩa: ${widget.meaning}',
                            style: AppTextStyles.latin(size: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // KHI CÓ KẾT QUẢ ĐÁNH GIÁ
                  if (_result != null) ...[
                    _buildResultView(),
                    const SizedBox(height: 24),
                  ] else ...[
                    // TRẠNG THÁI CHỜ/ĐANG NÓI
                    Center(
                      child: Container(
                        height: 120,
                        alignment: Alignment.center,
                        child: _isAnalyzing
                            ? const CircularProgressIndicator(color: AppColors.brand)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: _waveHeights.map((height) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: 6,
                                    height: height,
                                    decoration: BoxDecoration(
                                      color: _isListening ? AppColors.vocab : AppColors.border,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.latin(
                        size: 13,
                        color: _isListening ? AppColors.vocab : AppColors.textSecondary,
                        weight: _isListening ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // NÚT ĐIỀU KHIỂN MICRO
                  Center(
                    child: _isAnalyzing
                        ? const SizedBox(height: 72)
                        : GestureDetector(
                            onTap: _isListening ? _stopListeningAndAnalyze : _startListening,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final pulseScale = 1.0 + (_pulseController.value * 0.15);
                                return Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isListening ? const Color(0xFFFFEAEC) : const Color(0xFFF3F4F6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isListening ? AppColors.vocab : AppColors.textMuted).withOpacity(0.2),
                                        blurRadius: 10 * pulseScale,
                                        spreadRadius: 2 * _pulseController.value,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isListening ? AppColors.vocab : AppColors.textMuted,
                                    ),
                                    child: Icon(
                                      _isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildResultView() {
    final res = _result!;
    final scoreColor = res.score >= 80
        ? const Color(0xFF10B981) // Green
        : res.score >= 50
            ? const Color(0xFFF59E0B) // Orange
            : const Color(0xFFEF4444); // Red

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Vòng tròn điểm số animated
            AnimatedBuilder(
              animation: _scoreRingController,
              builder: (context, child) {
                final sweep = _scoreRingController.value * (res.score / 100);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: sweep,
                        strokeWidth: 7,
                        backgroundColor: AppColors.border,
                        color: scoreColor,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(res.score * _scoreRingController.value).round()}',
                          style: AppTextStyles.latin(size: 22, weight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Text(
                          'điểm',
                          style: AppTextStyles.latin(size: 8, color: AppColors.textSecondary, weight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 18),
            // Nhận xét chi tiết
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res.isMatch ? 'Phát âm tốt!' : 'Cần cố gắng thêm!',
                    style: AppTextStyles.latin(
                      size: 14,
                      weight: FontWeight.bold,
                      color: res.isMatch ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    res.feedback,
                    style: AppTextStyles.latin(size: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Từ bạn đã nói thực tế
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.interpreter_mode_outlined, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhận diện giọng bạn nói:',
                      style: AppTextStyles.latin(size: 10, color: AppColors.textMuted, weight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      res.transcript.isEmpty ? '(Không thu được từ nào)' : res.transcript,
                      style: AppTextStyles.jp(
                        size: 15,
                        color: res.transcript.isEmpty ? AppColors.textFaint : AppColors.brandDark,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

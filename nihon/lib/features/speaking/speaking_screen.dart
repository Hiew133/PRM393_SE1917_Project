import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/scenario.dart';
import 'speaking_controller.dart';
import 'widgets/ai_character.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/exam_cards.dart';
import 'widgets/speaking_bars.dart';
import 'widgets/voice_input_bar.dart';

/// Màn 07 – Luyện nói (hội thoại với AI).
///
/// Chế độ được quyết bởi [examScenario] (chọn ở màn trình độ):
/// - `null` → TỰ DO: trò chuyện tự do với AI.
/// - tình huống 会話 (id `exam_…`) → THI Nhật 3 (JPD316): AI đóng vai giảng viên.
/// - đề Nhật 1 đã bốc (examDrill, id `nihon1_…`) → THI Nhật 1 (JPD113): AI là
///   giám khảo, chạy hết format "đọc to bài đọc + 3 câu theo tranh + 1 câu tự do".
class SpeakingScreen extends StatefulWidget {
  final Scenario? examScenario;
  final String? title;

  /// Controller tiêm sẵn (widget test dùng để thay AI/mic bằng bản giả).
  /// Bình thường để null — màn tự tạo controller thật.
  @visibleForTesting
  final SpeakingController? controller;

  const SpeakingScreen(
      {super.key, this.examScenario, this.title, this.controller});

  bool get isExam => examScenario != null;

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  late final SpeakingController _controller;
  final ScrollController _scroll = ScrollController();

  /// Số tin nhắn đã xem trong sheet "Hội thoại & góp ý" — để hiện badge
  /// "có góp ý mới" trên nút mở script.
  int _seenCount = 0;

  /// Chế độ thi format cứng (Nhật 1 / Nhật 2 — AI là giám khảo).
  bool get _isExamDrill => widget.examScenario?.examDrill ?? false;

  /// Nhật 2 (JPD123): đọc 45đ + 3 câu Q&A; Nhật 1 (JPD113): đọc 30đ + 4 câu.
  bool get _isNihon2 =>
      widget.examScenario?.drillType == ExamDrillType.nihon2;

  /// Chế độ thi Nhật 3 (JPD316, hội thoại theo đề giảng viên).
  bool get _isJpd316 => widget.isExam && !_isExamDrill;

  /// Thẻ BÀI ĐỌC chỉ ghim trong giai đoạn READING (SV đọc to đoạn văn).
  bool get _showReadingCard =>
      _isExamDrill &&
      _controller.readingPassage != null &&
      (_controller.examPhase ?? 'reading') == 'reading';

  /// Thẻ TRANH thay chỗ bài đọc khi sang phần câu hỏi theo tranh.
  bool get _showPictureCard =>
      _isExamDrill &&
      _controller.examPhase == 'picture' &&
      widget.examScenario?.examPicture != null;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        SpeakingController(initialScenario: widget.examScenario);
    _controller.addListener(_onChange);
    _controller.init();
  }

  void _onChange() {
    // Tự cuộn xuống cuối khi có tin nhắn mới.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                _header(),
                if (_showReadingCard)
                  ExamReadingCard(
                    jp: _controller.readingPassage ?? '',
                    vi: _controller.readingPassageVi,
                    points: _isNihon2 ? 45 : 30,
                  ),
                if (_showPictureCard)
                  ExamPictureCard(picture: widget.examScenario!.examPicture!),
                if (_isExamDrill && _controller.examFinished)
                  ExamResultCard(
                    scores: _controller.examTurnScores,
                    readingMax: _isNihon2 ? 45 : 30,
                    questionCount: _isNihon2 ? 3 : 4,
                  ),
                if (_isExamDrill && _controller.examProgress != null)
                  ExamProgressChip(
                    label: _controller.examProgress ?? '',
                    done: _controller.examFinished,
                  ),
                if (_isJpd316)
                  ActiveExamBanner(
                    jpLabel: _controller.scenario.jpLabel,
                    viLabel: _controller.scenario.viLabel,
                  ),
                if (_controller.error != null)
                  ErrorBanner(message: _controller.error!),
                Expanded(child: _stage()),
                if (_isExamDrill && _controller.examFinished)
                  ExamDoneBar(onBack: () => Navigator.maybePop(context))
                else if (_controller.sessionEnded)
                  SessionEndedBar(onRestart: _controller.restart)
                else
                  VoiceInputBar(
                    listening: _controller.listening,
                    // finishing: đang chốt câu (~400ms) — khóa nút như lúc bận
                    // để bấm nhanh không mở phiên mới đè lên phiên đang đóng.
                    busy: _controller.busy || _controller.finishing,
                    partialText: _controller.partialText,
                    draftText: _controller.draft,
                    onMicTap: _controller.toggleMic,
                    onSendDraft: _controller.sendDraft,
                    onDiscardDraft: _controller.discardDraft,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    final Widget center;
    if (_isExamDrill) {
      center = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              _isNihon2
                  ? '日本語２ thi nói · AI là giám khảo'
                  : '日本語１ thi nói · AI là giám khảo',
              style: AppTextStyles.jp(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.speaking)),
          Text(
              widget.title ??
                  (_isNihon2
                      ? 'Đọc to bài (45đ) + 3 câu hỏi (45đ)'
                      : 'Đọc to bài (30đ) + 4 câu hỏi (60đ)'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.latin(size: 11, color: AppColors.textMuted)),
        ],
      );
    } else if (_isJpd316) {
      center = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('会話 thi · AI đóng vai giảng viên',
              style: AppTextStyles.jp(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.kanji)),
          if (widget.title != null)
            Text(widget.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTextStyles.latin(size: 11, color: AppColors.textMuted)),
        ],
      );
    } else {
      center = Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.speaking,
            ),
          ),
          const SizedBox(width: 7),
          Text('発音練習', style: AppTextStyles.jp(size: 15)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 14),
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: center),
          // Tự do + JPD316: nút kết thúc buổi luyện → AI tổng kết. Thi Nhật 1
          // tự kết thúc theo format nên không có nút này.
          if (!_isExamDrill) _endSessionButton(),
        ],
      ),
    );
  }

  /// Nút "Kết thúc" (chế độ Tự do / JPD316) — chỉ bấm được khi đã nói ít nhất
  /// 1 câu và không đang bận/nghe.
  Widget _endSessionButton() {
    final c = _controller;
    final enabled =
        c.hasUserTurn && !c.busy && !c.listening && !c.sessionEnded;
    return TextButton.icon(
      onPressed: enabled ? c.endSession : null,
      icon: const Icon(Icons.flag_outlined, size: 15),
      label: const Text('Kết thúc'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.speaking,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: AppTextStyles.latin(size: 12, weight: FontWeight.w700),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  /// Trạng thái hiện tại của nhân vật → (chữ, màu) cho pill dưới nhân vật.
  ({String text, Color color}) _statusInfo() {
    final c = _controller;
    if (c.listening) {
      return (text: 'Đang nghe bạn nói… 🎤', color: AppColors.vocab);
    }
    if (c.finishing) {
      return (text: 'Đang chốt câu… ✍️', color: AppColors.brand);
    }
    if (c.draft != null) {
      return (text: 'Xem lại câu rồi bấm gửi ✏️', color: AppColors.brand);
    }
    if (c.busy) {
      return (text: 'Đang suy nghĩ…', color: AppColors.srsMaster);
    }
    if (c.aiSpeaking) {
      return (text: 'Đang nói · nghe nhé 🔊', color: AppColors.speaking);
    }
    if (_isExamDrill && c.examFinished) {
      return (text: 'Thi xong rồi · おつかれさま！', color: AppColors.speaking);
    }
    if (c.sessionEnded) {
      return (text: 'Hết buổi luyện · おつかれさま！', color: AppColors.speaking);
    }
    if (_isExamDrill && c.examPhase == 'reading') {
      return (
        text: 'Bấm mic rồi ĐỌC TO bài đọc 📖',
        color: AppColors.speaking
      );
    }
    return (text: 'Sẵn sàng · bấm mic để nói', color: AppColors.textMuted);
  }

  String get _roleLabel {
    if (_isExamDrill) return 'Giám khảo · 試験官';
    if (_isJpd316) return 'Giảng viên · 先生';
    return 'Bạn đồng hành · AI';
  }

  /// VÙNG GIỮA: thẻ bài đọc/tranh (nếu có) + nhân vật「さくら先生」. Cuộn được
  /// khi màn hẹp nên nhân vật LUÔN hiện đủ (không bị co mất) và không bao giờ
  /// tràn. Màn rộng thì căn giữa như sân khấu.
  Widget _stage() {
    return LayoutBuilder(builder: (context, box) {
      final hasCard = _showReadingCard || _showPictureCard;
      // Nhân vật: to khi chat tự do, nhỏ gọn nhưng vẫn rõ khi có thẻ bài đọc/
      // tranh choán chỗ ở trên.
      final dim = math
          .min(box.maxWidth * (hasCard ? 0.34 : 0.5), hasCard ? 130.0 : 220.0)
          .toDouble();
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(child: _characterBlock(dim)),
        ),
      );
    });
  }

  /// Nhân vật ảo「さくら先生」+ tên/vai + pill trạng thái + nút mở script.
  Widget _characterBlock(double dim) {
    final c = _controller;
    final status = _statusInfo();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          width: dim,
          height: dim,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Quầng sáng "sân khấu" — Positioned nên vẽ tràn ra sau lưng.
              Positioned(
                child: IgnorePointer(
                  child: Container(
                    width: dim * 1.35,
                    height: dim * 1.35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          status.color.withValues(alpha: 0.14),
                          status.color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AiCharacter(
                size: dim,
                speaking: c.aiSpeaking,
                listening: c.listening,
                thinking: c.busy,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text('さくら先生',
            style: AppTextStyles.jp(size: 17, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(_roleLabel,
            style: AppTextStyles.latin(size: 11, color: AppColors.textFaint)),
        const SizedBox(height: 8),
        // Pill trạng thái.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: status.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: status.color),
              ),
              const SizedBox(width: 7),
              Text(status.text,
                  style: AppTextStyles.latin(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: status.color)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _scriptButton(),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Nút mở sheet "Hội thoại & góp ý" — script được ẨN, chỉ hiện khi bấm.
  Widget _scriptButton() {
    final total = _controller.messages.where((m) => !m.isPending).length;
    final unseen = (total - _seenCount).clamp(0, 99);

    return GestureDetector(
      onTap: total == 0 ? null : _openScriptSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 17, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text('Xem hội thoại & góp ý',
                style: AppTextStyles.latin(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            if (unseen > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.vocab,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$unseen',
                    style: AppTextStyles.latin(
                        size: 11,
                        weight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Bottom sheet chứa toàn bộ script hội thoại + góp ý (hint) của AI.
  void _openScriptSheet() {
    // Cuộn tới tin mới nhất ngay khi sheet vừa dựng xong.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Tay kéo.
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                    child: Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Hội thoại & góp ý',
                              style: AppTextStyles.latin(
                                  size: 15, weight: FontWeight.w800)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close,
                              size: 20, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(child: _chatList()),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Đóng sheet → đánh dấu đã xem hết để tắt badge.
      if (!mounted) return;
      setState(() {
        _seenCount = _controller.messages.where((m) => !m.isPending).length;
      });
    });
  }















  Widget _chatList() {
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      itemCount: _controller.messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final m = _controller.messages[i];
        return ChatBubble(
          message: m,
          onListen: m.fromUser ? null : () => _controller.speak(m.japanese),
        );
      },
    );
  }


}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/scenario.dart';
import 'speaking_controller.dart';
import 'widgets/ai_character.dart';
import 'widgets/chat_bubble.dart';
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
  const SpeakingScreen({super.key, this.examScenario, this.title});

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

  /// Chế độ thi Nhật 1 (giám khảo: đọc to + 3 câu tranh + 1 câu tự do).
  bool get _isExamDrill => widget.examScenario?.examDrill ?? false;

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
    _controller = SpeakingController(initialScenario: widget.examScenario);
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
                if (_showReadingCard) _readingCard(),
                if (_showPictureCard) _pictureCard(),
                if (_isExamDrill && _controller.examFinished)
                  _examResultCard(),
                if (_isExamDrill && _controller.examProgress != null)
                  _examProgressBar(),
                if (_isJpd316) _activeExamBanner(),
                if (_controller.error != null) _errorBanner(_controller.error!),
                Expanded(child: _stage()),
                if (_isExamDrill && _controller.examFinished)
                  _examDoneBar()
                else if (_controller.sessionEnded)
                  _sessionEndedBar()
                else
                  VoiceInputBar(
                    listening: _controller.listening,
                    busy: _controller.busy,
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
          Text('日本語１ thi nói · AI là giám khảo',
              style: AppTextStyles.jp(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.speaking)),
          Text(widget.title ?? 'Đọc to bài (30đ) + 4 câu hỏi (60đ)',
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

  /// Thẻ "bài đọc" ghim trên cùng (chế độ thi Nhật 1).
  Widget _readingCard() {
    final jp = _controller.readingPassage ?? '';
    final vi = _controller.readingPassageVi;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F2),
        border: Border.all(color: AppColors.speaking.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('BÀI ĐỌC · よんでください',
                    style: AppTextStyles.overline
                        .copyWith(color: AppColors.speaking)),
              ),
              Text('30đ',
                  style: AppTextStyles.latin(
                      size: 10,
                      weight: FontWeight.w800,
                      color: AppColors.speaking)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Bấm mic rồi ĐỌC TO đoạn văn — chỉ cần đọc đúng, không phải trả lời.',
              style: AppTextStyles.latin(
                  size: 10.5, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jp,
                      style: AppTextStyles.jp(
                          size: 15, height: 1.6, weight: FontWeight.w600)),
                  if (vi != null && vi.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(vi,
                        style: AppTextStyles.latin(
                            size: 12,
                            height: 1.45,
                            color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ TRANH ghim trên cùng (phần TALKING WITH PICTURES của thi Nhật 1) —
  /// thay chỗ thẻ bài đọc; emoji to + các gợi ý ghi trên tranh để SV trả lời.
  Widget _pictureCard() {
    final pic = widget.examScenario!.examPicture!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FD),
        border: Border.all(
            color: AppColors.srsMaster.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🖼️', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('TRANH · えを　みて　こたえてください',
                    style: AppTextStyles.overline
                        .copyWith(color: AppColors.srsMaster)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Tranh" — emoji to trong khung.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: AppColors.srsMaster.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(pic.emoji,
                      style: const TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pic.caption,
                        style: AppTextStyles.jp(
                            size: 15, weight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final h in pic.hints)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(h,
                                style: AppTextStyles.jp(
                                    size: 12, weight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Thẻ KẾT QUẢ ước lượng sau khi thi Nhật 1 xong — tính từ điểm AI chấm
  /// từng lượt, quy về đúng cơ cấu đề: ĐỌC 30đ + 4 câu × 15đ + tác phong 10đ
  /// (tác phong ước theo trung bình các lượt vì AI không thấy tác phong thật).
  Widget _examResultCard() {
    final scores = _controller.examTurnScores;
    int? at(int i) => i < scores.length ? scores[i] : null;

    final graded = [for (var i = 0; i < 5; i++) at(i)].whereType<int>();
    final avg = graded.isEmpty
        ? 0
        : graded.reduce((a, b) => a + b) / graded.length;

    final reading = ((at(0) ?? 0) * 0.30).round(); // /30
    final qs = [for (var i = 1; i <= 4; i++) ((at(i) ?? 0) * 0.15).round()];
    final manner = (avg * 0.10).round(); // /10
    final total = reading + qs.reduce((a, b) => a + b) + manner;

    Widget chip(String label, int pts, int max) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border.all(color: AppColors.speaking.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTextStyles.latin(
                    size: 11, color: AppColors.textMuted)),
            const SizedBox(width: 5),
            Text('$pts/$max',
                style: AppTextStyles.latin(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: AppColors.speaking)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F2),
        border: Border.all(color: AppColors.speaking.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('KẾT QUẢ (ước lượng)',
                    style: AppTextStyles.overline
                        .copyWith(color: AppColors.speaking)),
              ),
              Text('$total',
                  style: AppTextStyles.latin(
                      size: 20,
                      weight: FontWeight.w800,
                      color: AppColors.speaking)),
              Text('/100',
                  style: AppTextStyles.latin(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              chip('Đọc bài', reading, 30),
              for (var i = 0; i < 4; i++) chip('Câu ${i + 1}', qs[i], 15),
              chip('Tác phong', manner, 10),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'AI chấm ước lượng qua nhận diện giọng nói — điểm tham khảo để ôn tập.',
            style: AppTextStyles.latin(size: 10, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }

  /// Thanh thay cho mic khi đã kết thúc buổi luyện (chế độ Tự do / JPD316).
  Widget _sessionEndedBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, color: AppColors.speaking, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Đã kết thúc buổi luyện.',
                style: AppTextStyles.latin(size: 13, weight: FontWeight.w600)),
          ),
          TextButton.icon(
            onPressed: _controller.restart,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Luyện lại'),
            style: TextButton.styleFrom(foregroundColor: AppColors.speaking),
          ),
        ],
      ),
    );
  }

  /// Chip tiến độ "Câu x/4" (chế độ thi Nhật 1).
  Widget _examProgressBar() {
    final done = _controller.examFinished;
    final color = done ? AppColors.speaking : AppColors.srsMaster;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(done ? Icons.check_circle : Icons.timelapse,
                    size: 13, color: color),
                const SizedBox(width: 5),
                Text(_controller.examProgress ?? '',
                    style: AppTextStyles.latin(
                        size: 11, weight: FontWeight.w700, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh thay cho mic khi đã thi xong (chế độ thi Nhật 1).
  Widget _examDoneBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.speaking, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Đã hoàn thành phần thi.',
                style: AppTextStyles.latin(
                    size: 13, weight: FontWeight.w600)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Bốc đề khác'),
            style: TextButton.styleFrom(foregroundColor: AppColors.speaking),
          ),
        ],
      ),
    );
  }

  Widget _activeExamBanner() {
    final s = _controller.scenario;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('🎓', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Đang luyện theo đề · ${s.jpLabel} — ${s.viLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.latin(
                  size: 11,
                  weight: FontWeight.w600,
                  color: const Color(0xFF7B3FA8)),
            ),
          ),
        ],
      ),
    );
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

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      // Giới hạn chiều cao để thông báo lỗi (dù dài) không bao giờ làm tràn layout.
      constraints: const BoxConstraints(maxHeight: 120),
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: Text(
          message,
          style: AppTextStyles.latin(size: 12, color: AppColors.vocab),
        ),
      ),
    );
  }
}

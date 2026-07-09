import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../speaking/speaking_screen.dart';
import 'data/admin_repository.dart';
import 'exam_scenario.dart';
import 'models/admin_models.dart';

/// S07 — Mở đề phía SV: hiện tình huống 会話 của đề (mỗi đề 1 tình huống, biến
/// thể lấy từ nhiều đề), xem 場面 + 文法 và đếm ngược thời gian chuẩn bị tại chỗ.
class StudentDrawScreen extends StatefulWidget {
  final Exam exam;

  /// true → tự quay bốc đề ngay khi mở màn (dùng khi vào từ nút 🎲 phía SV).
  final bool autoDraw;
  const StudentDrawScreen({super.key, required this.exam, this.autoDraw = false});

  @override
  State<StudentDrawScreen> createState() => _StudentDrawScreenState();
}

enum _DrawState { idle, shuffling, drawn }

class _StudentDrawScreenState extends State<StudentDrawScreen> {
  final _repo = AdminRepository.instance;
  final _rng = Random();

  _DrawState _state = _DrawState.idle;
  ConversationSituation? _result;
  String _preview = '会話'; // nhãn nhấp nháy khi đang quay
  int _remaining = 0; // giây còn lại
  bool _started = false;
  Timer? _shuffleTimer;
  Timer? _countdown;

  // Nhãn nhấp nháy lúc quay (chỉ để tạo hiệu ứng, không phản ánh số lượng).
  static const _spinLabels = ['会話1.1', '会話2.1', '会話3.1'];

  static const _bg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A1C0C), Color(0xFF3D2412), Color(0xFF4A2F18)],
    stops: [0, 0.6, 1],
  );

  @override
  void initState() {
    super.initState();
    if (widget.autoDraw) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _state == _DrawState.idle) _draw();
      });
    }
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    _countdown?.cancel();
    super.dispose();
  }

  List<ConversationSituation> get _all => _repo.situationsForExam(widget.exam.id);
  List<ConversationSituation> get _drafted =>
      _all.where((s) => s.drafted).toList();

  void _draw() {
    final pool = _drafted;
    if (pool.isEmpty) return;
    setState(() => _state = _DrawState.shuffling);
    var ticks = 0;
    _shuffleTimer?.cancel();
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 70), (t) {
      ticks++;
      setState(() => _preview = _spinLabels[_rng.nextInt(_spinLabels.length)]);
      if (ticks >= 16) {
        t.cancel();
        _settle(pool);
      }
    });
  }

  void _settle(List<ConversationSituation> pool) {
    final picked = pool[_rng.nextInt(pool.length)];
    setState(() {
      _result = picked;
      _state = _DrawState.drawn;
      _remaining = widget.exam.conversationPrepSeconds;
    });
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _ready() {
    final s = _result;
    if (s == null) return;
    _countdown?.cancel();
    setState(() {
      _started = true;
      _remaining = 0;
    });
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SpeakingScreen(
        examScenario: buildExamScenario(s),
        title: '${s.baseTemplate} · ${widget.exam.title}',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _bg),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _repo,
            builder: (context, _) => switch (_state) {
              _DrawState.drawn => _drawnView(),
              _ => _idleView(),
            },
          ),
        ),
      ),
    );
  }

  Widget _backRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.14))),
              child: const Icon(Icons.chevron_left, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(widget.exam.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.latin(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85))),
          ),
        ],
      ),
    );
  }

  // ── Chưa bốc / đang quay ───────────────────────────────
  Widget _idleView() {
    final shuffling = _state == _DrawState.shuffling;
    final count = _drafted.length;
    final ready = count > 0;
    return Column(
      children: [
        _backRow(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _badge('会話 · ${widget.exam.conversationPoints}点'),
                  const SizedBox(height: 24),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF9B4FCC), Color(0xFF7B3FA8)],
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.kanji.withValues(alpha: 0.5),
                            blurRadius: 48,
                            offset: const Offset(0, 16)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: shuffling
                        ? Text(_preview,
                            style: AppTextStyles.jp(
                                size: 40,
                                weight: FontWeight.w800,
                                color: Colors.white,
                                height: 1))
                        : const Icon(Icons.casino,
                            size: 88, color: Colors.white),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    shuffling
                        ? 'Đang mở đề…'
                        : ready
                            ? 'Nhấn để mở tình huống 会話 của đề'
                            : 'Đề chưa có tình huống 会話 được soạn',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.latin(
                        size: 14,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: GestureDetector(
            onTap: ready && !shuffling ? _draw : null,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ready && !shuffling
                    ? const Color(0xFFF7C547)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                boxShadow: ready && !shuffling
                    ? [
                        BoxShadow(
                            color: const Color(0xFFF7C547)
                                .withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8))
                      ]
                    : null,
              ),
              child: Text(shuffling ? 'Đang bốc…' : '🎲  Bốc đề ngay',
                  style: AppTextStyles.latin(
                      size: 16,
                      weight: FontWeight.w800,
                      color: ready && !shuffling
                          ? const Color(0xFF2A1C0C)
                          : Colors.white38)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Đã bốc ─────────────────────────────────────────────
  Widget _drawnView() {
    final s = _result!;
    return Column(
      children: [
        _backRow(),
        const SizedBox(height: 8),
        _badge('会話 · ${widget.exam.conversationPoints}点'),
        const SizedBox(height: 4),
        Text('Bạn đã bốc trúng tình huống',
            style: AppTextStyles.latin(
                size: 13, color: Colors.white.withValues(alpha: 0.5))),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: _numberCard(s),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: _countdownBar(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
            children: [
              _roleCard(s),
              const SizedBox(height: 12),
              _grammarCard(s),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: GestureDetector(
            onTap: _started ? null : _ready,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _started
                    ? AppColors.speaking
                    : const Color(0xFFF7C547),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                  _started
                      ? '✓ Đang thi với giảng viên'
                      : 'Sẵn sàng · Bắt đầu hội thoại →',
                  style: AppTextStyles.latin(
                      size: 16,
                      weight: FontWeight.w800,
                      color: _started ? Colors.white : const Color(0xFF2A1C0C))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.kanji.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kanji.withValues(alpha: 0.4)),
      ),
      child: Text(text,
          style: AppTextStyles.jp(
              size: 13,
              weight: FontWeight.w700,
              color: const Color(0xFFC89AEF))),
    );
  }

  Widget _numberCard(ConversationSituation s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B4FCC), Color(0xFF7B3FA8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.kanji.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        children: [
          Text('TÌNH HUỐNG 会話',
              style: AppTextStyles.latin(
                  size: 12,
                  weight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 6),
          Text(s.baseTemplate,
              style: AppTextStyles.jp(
                  size: 46,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  height: 1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text(s.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.latin(
                    size: 13, weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _countdownBar() {
    final total = widget.exam.conversationPrepSeconds;
    final frac = total == 0 ? 0.0 : _remaining / total;
    final done = _remaining == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: frac,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFFF7C547)),
                  ),
                ),
                Text('$_remaining',
                    style: AppTextStyles.latin(
                        size: 17,
                        weight: FontWeight.w800,
                        color: const Color(0xFFF7C547))),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(done ? 'Hết giờ chuẩn bị' : 'Thời gian chuẩn bị',
                    style: AppTextStyles.latin(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 1),
                Text(
                    'Đọc kỹ vai & ngữ pháp · ${widget.exam.conversationPrepSeconds} giây tại chỗ',
                    style: AppTextStyles.latin(
                        size: 12, color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleCard(ConversationSituation s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: AppColors.kanji,
                    borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: Text('S',
                    style: AppTextStyles.latin(
                        size: 11,
                        weight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 7),
              Text('VAI CỦA BẠN', style: AppTextStyles.overline),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            s.scenarioStudent.isEmpty
                ? 'Chưa có mô tả 場面 cho tình huống này.'
                : s.scenarioStudent,
            style: AppTextStyles.jp(
                size: 14, weight: FontWeight.w400, height: 1.8),
          ),
          if (s.changeNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFFCF6E8),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Chi tiết có thể đổi: ${s.changeNote}',
                  style: AppTextStyles.latin(
                      size: 11,
                      weight: FontWeight.w600,
                      color: const Color(0xFF9A6B1E))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _grammarCard(ConversationSituation s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PHẢI DÙNG 文法', style: AppTextStyles.overline),
          const SizedBox(height: 10),
          if (s.grammar.isEmpty)
            Text('—',
                style: AppTextStyles.jp(size: 14, color: AppColors.textMuted))
          else
            for (var i = 0; i < s.grammar.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == s.grammar.length - 1 ? 0 : 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F0FF),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Text('${i + 1}',
                          style: AppTextStyles.latin(
                              size: 11,
                              weight: FontWeight.w800,
                              color: AppColors.kanji)),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(s.grammar[i],
                            style: AppTextStyles.jp(
                                size: 15,
                                weight: FontWeight.w700,
                                color: AppColors.kanji)),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

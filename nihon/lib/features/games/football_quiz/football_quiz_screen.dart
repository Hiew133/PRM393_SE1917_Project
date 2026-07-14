import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'football_question.dart';

/// Trò chơi "Thủ môn bắt bóng" — trả lời ngữ pháp theo kiểu đá bóng.
///
/// Chọn áo số (1–10) và số câu (5/7/10) → mỗi câu chọn 1 trong 4 đáp án:
/// đúng thì bóng bay vào lưới (ghi bàn), sai thì thủ môn bắt được.
/// Câu hỏi viết cứng ([kFootballQuestions]) nên mở là chơi ngay, không lag.
class FootballQuizScreen extends StatefulWidget {
  const FootballQuizScreen({super.key});

  @override
  State<FootballQuizScreen> createState() => _FootballQuizScreenState();
}

enum _Phase { setup, playing, result }

/// Câu hỏi đã trộn thứ tự đáp án cho một ván.
class _RoundQuestion {
  final FootballQuestion base;
  final List<String> options;
  final int correctIndex;
  _RoundQuestion(this.base, this.options, this.correctIndex);
}

class _FootballQuizScreenState extends State<FootballQuizScreen>
    with SingleTickerProviderStateMixin {
  static const _asStadium = 'assets/images/football/stadium.png';
  static const _asField = 'assets/images/football/field.png';
  static const _asKeeperIdle = 'assets/images/football/keeper_idle.png';
  static const _asKeeperDive = 'assets/images/football/keeper_dive.png';

  final Random _rng = Random();

  _Phase _phase = _Phase.setup;
  int _jersey = 10;
  int _count = 5;

  late List<_RoundQuestion> _round;
  int _index = 0;
  int _goals = 0;

  int? _picked;
  bool _answered = false;
  bool _lastCorrect = false;

  late final AnimationController _ballCtrl;

  @override
  void initState() {
    super.initState();
    _ballCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    _ballCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    final pool = List<FootballQuestion>.from(kFootballQuestions)..shuffle(_rng);
    final picked = pool.take(_count).map((q) {
      // Trộn thứ tự đáp án, giữ dấu đáp án đúng theo giá trị.
      final opts = List<String>.from(q.options)..shuffle(_rng);
      return _RoundQuestion(q, opts, opts.indexOf(q.correctAnswer));
    }).toList();

    setState(() {
      _round = picked;
      _index = 0;
      _goals = 0;
      _picked = null;
      _answered = false;
      _phase = _Phase.playing;
    });
  }

  Future<void> _answer(int optionIndex) async {
    if (_answered) return;
    final q = _round[_index];
    final correct = optionIndex == q.correctIndex;
    setState(() {
      _picked = optionIndex;
      _answered = true;
      _lastCorrect = correct;
      if (correct) _goals++;
    });

    _ballCtrl.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;

    if (_index + 1 >= _round.length) {
      setState(() => _phase = _Phase.result);
    } else {
      setState(() {
        _index++;
        _picked = null;
        _answered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2C4A),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.setup => _buildSetup(),
          _Phase.playing => _buildPlaying(),
          _Phase.result => _buildResult(),
        },
      ),
    );
  }

  // ── SETUP ────────────────────────────────────────────────
  Widget _buildSetup() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_asStadium, fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.35)),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 8),
              Text('⚽ Thủ môn bắt bóng',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.latin(size: 26, weight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Trả lời ngữ pháp đúng để sút tung lưới!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.latin(size: 14, color: Colors.white70)),
              const SizedBox(height: 24),
              _panel(
                title: 'Chọn áo số của bạn',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int n = 1; n <= 10; n++) _jerseyChip(n),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _panel(
                title: 'Số câu hỏi',
                child: Row(
                  children: [
                    for (final c in [5, 7, 10]) ...[
                      Expanded(child: _countChip(c)),
                      if (c != 10) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Vào sân ⚽',
                    style: AppTextStyles.latin(size: 18, weight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.latin(size: 14, weight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _jerseyChip(int n) {
    final selected = _jersey == n;
    return GestureDetector(
      onTap: () => setState(() => _jersey = n),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.brandDark : AppColors.border,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text('$n',
            style: AppTextStyles.latin(
              size: 20,
              weight: FontWeight.w900,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }

  Widget _countChip(int c) {
    final selected = _count == c;
    return GestureDetector(
      onTap: () => setState(() => _count = c),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.speaking : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.speaking : AppColors.border, width: 2),
        ),
        alignment: Alignment.center,
        child: Text('$c câu',
            style: AppTextStyles.latin(
              size: 15,
              weight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }

  // ── PLAYING ──────────────────────────────────────────────
  Widget _buildPlaying() {
    final q = _round[_index];
    return Column(
      children: [
        _hud(),
        // Băng câu hỏi
        Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2F80ED), Color(0xFF56A0F0)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(q.base.sentence,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.jp(size: 20, weight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text(q.base.hintVi,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.latin(size: 12.5, color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
        ),
        // Sân + thủ môn + bóng
        Expanded(child: _pitch()),
        // 4 đáp án
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: _optionsGrid(q),
        ),
      ],
    );
  }

  Widget _hud() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 14, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          _hudChip('Câu ${_index + 1}/${_round.length}', Icons.sports_soccer),
          const SizedBox(width: 8),
          _hudChip('$_goals bàn', Icons.emoji_events, color: AppColors.brand),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Áo số $_jersey',
                style: AppTextStyles.latin(size: 12, weight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _hudChip(String text, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color ?? Colors.white),
          const SizedBox(width: 5),
          Text(text, style: AppTextStyles.latin(size: 12, weight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _pitch() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final keeperH = (h * 0.34).clamp(110.0, 240.0);
        final ballSize = (h * 0.14).clamp(44.0, 96.0);
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Khán đài làm nền (lộ ra ở phần trời phía trên sân).
              Positioned.fill(
                child: Image.asset(_asStadium, fit: BoxFit.cover),
              ),
              // Nền sân cỏ phủ kín vùng chơi (khung thành ở phía trên).
              Positioned.fill(
                child: Image.asset(
                  _asField,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              // Thủ môn (đứng trước khung thành).
              _buildKeeper(keeperH),
              // Bóng
              _buildBall(ballSize),
              // Hiệu ứng bàn thắng
              if (_answered && _lastCorrect) _goalBurst(ballSize),
              // Nhãn kết quả
              if (_answered) _resultTag(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeeper(double keeperH) {
    return AnimatedBuilder(
      animation: _ballCtrl,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_ballCtrl.value);
        Alignment pos;
        Widget keeper;
        if (_answered && _lastCorrect) {
          // Đúng: thủ môn bay NHẦM hướng (sang trái), để lộ khung thành.
          pos = Alignment.lerp(
            const Alignment(0, -0.32),
            const Alignment(-0.55, -0.12),
            t,
          )!;
          keeper = _diveKeeper(keeperH);
        } else if (_answered && !_lastCorrect) {
          // Sai: thủ môn bay ra bắt dính bóng ở giữa.
          pos = const Alignment(0, -0.24);
          keeper = _diveKeeper(keeperH);
        } else {
          pos = const Alignment(0, -0.32);
          keeper = Image.asset(_asKeeperIdle, height: keeperH);
        }
        return Align(
          alignment: pos,
          child: SizedBox(height: keeperH, child: keeper),
        );
      },
    );
  }

  /// Ảnh thủ môn bay chỉ lấy NỬA trái (file gốc có 2 tư thế).
  Widget _diveKeeper(double keeperH) {
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: 0.5,
        child: Image.asset(_asKeeperDive, height: keeperH),
      ),
    );
  }

  Widget _buildBall(double ballSize) {
    return AnimatedBuilder(
      animation: _ballCtrl,
      builder: (context, child) {
        final e = Curves.easeOut.transform(_ballCtrl.value);
        const start = Alignment(0, 0.72);
        late Alignment pos;
        double scale;
        if (!_answered) {
          pos = start;
          scale = 1.0;
        } else if (_lastCorrect) {
          // Bay vào góc trên khung thành.
          pos = Alignment.lerp(start, const Alignment(0.42, -0.5), e)!;
          scale = 1.0 - 0.55 * e; // xa dần → nhỏ dần (phối cảnh)
        } else {
          // Bay tới tay thủ môn rồi dừng (bị bắt).
          pos = Alignment.lerp(start, const Alignment(0, -0.18), e)!;
          scale = 1.0 - 0.5 * e;
        }
        return Align(
          alignment: pos,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: _SoccerBall(size: ballSize),
    );
  }

  Widget _goalBurst(double ballSize) {
    return Align(
      alignment: const Alignment(0.42, -0.5),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, v, child) {
          return Opacity(
            opacity: (v * 1.4).clamp(0.0, 1.0) * (1.0 - (v - 0.7).clamp(0.0, 0.3)),
            child: Transform.scale(
              scale: 0.4 + v * 1.4,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFE07A).withValues(alpha: 0.9),
                      const Color(0xFFFFB020).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _resultTag() {
    final correct = _lastCorrect;
    return Align(
      alignment: const Alignment(0, -0.9),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        builder: (context, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: correct ? AppColors.speaking : AppColors.vocab,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: (correct ? AppColors.speaking : AppColors.vocab).withValues(alpha: 0.5),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            correct ? '⚽ VÀO! Ghi bàn!' : '🧤 Thủ môn bắt được!',
            style: AppTextStyles.latin(size: 15, weight: FontWeight.w900, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _optionsGrid(_RoundQuestion q) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3.0,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        for (int i = 0; i < q.options.length; i++) _optionButton(q, i),
      ],
    );
  }

  Widget _optionButton(_RoundQuestion q, int i) {
    const labels = ['A', 'B', 'C', 'D'];
    Color bg = const Color(0xFF2F80ED);
    Color border = const Color(0xFF1F5FBF);
    if (_answered) {
      if (i == q.correctIndex) {
        bg = AppColors.speaking;
        border = const Color(0xFF2E8B57);
      } else if (i == _picked) {
        bg = AppColors.vocab;
        border = const Color(0xFFB23A28);
      } else {
        bg = const Color(0xFF6B7A8D);
        border = const Color(0xFF55606E);
      }
    }
    return GestureDetector(
      onTap: _answered ? null : () => _answer(i),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(labels[i],
                  style: AppTextStyles.latin(size: 13, weight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(q.options[i],
                  style: AppTextStyles.jp(size: 17, weight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── RESULT ───────────────────────────────────────────────
  Widget _buildResult() {
    final total = _round.length;
    final pct = total == 0 ? 0 : (_goals * 100 / total).round();
    final stars = _goals >= total ? 3 : (pct >= 60 ? 2 : (pct >= 30 ? 1 : 0));
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_asStadium, fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.45)),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(_asKeeperIdle, height: 150),
              const SizedBox(height: 12),
              Text('Kết thúc trận đấu!',
                  style: AppTextStyles.latin(size: 24, weight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++)
                    Icon(
                      i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.brand,
                      size: 44,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text('$_goals / $total',
                        style: AppTextStyles.latin(size: 40, weight: FontWeight.w900, color: AppColors.speaking)),
                    Text('bàn thắng ghi được',
                        style: AppTextStyles.latin(size: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Chơi lại',
                      style: AppTextStyles.latin(size: 16, weight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Colors.white70, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Về phần Ngữ pháp',
                      style: AppTextStyles.latin(size: 15, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Quả bóng vẽ bằng widget (không tốn asset) để nhẹ và sắc nét mọi kích cỡ.
class _SoccerBall extends StatelessWidget {
  final double size;
  const _SoccerBall({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Icon(Icons.sports_soccer, size: size, color: Colors.white),
    );
  }
}

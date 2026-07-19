import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/guest_lock_dialog.dart';
import '../lessons/kanji_data.dart';
import '../lessons/kanji_writing_canvas.dart';
import 'kana_data.dart';
import 'kana_stroke_loader.dart';

/// Quiz ôn bảng chữ cái Kana kiểu Tofugu: chọn hàng trong bảng Hiragana /
/// Katakana rồi luyện từng chữ theo 1 trong 2 chế độ:
/// - GÕ ROMAJI: hiện chữ kana → gõ cách đọc (như cũ).
/// - VIẾT CHỮ: hiện romaji → VIẾT chữ kana lên canvas, chấm từng nét
///   (tái dùng canvas luyện viết Kanji; nét mẫu từ KanjiVG bundle sẵn).
/// Sai thì lặp lại đến khi thuộc.
class KanaQuizScreen extends StatefulWidget {
  const KanaQuizScreen({super.key});

  @override
  State<KanaQuizScreen> createState() => _KanaQuizScreenState();
}

enum _Phase { setup, quiz, result }
enum _Feedback { none, correct, wrong }

class _KanaQuizScreenState extends State<KanaQuizScreen> {
  final Random _rng = Random();

  _Phase _phase = _Phase.setup;

  // ── Chọn bảng ────────────────────────────────────────────
  bool _showKatakana = false; // false = Hiragana, true = Katakana
  final Set<int> _selHira = {};
  final Set<int> _selKata = {};

  // ── Chế độ luyện ─────────────────────────────────────────
  bool _writeMode = false; // false = gõ romaji, true = viết chữ

  /// Chế độ VIẾT chữ chỉ dành cho tài khoản đã đăng nhập (Khách bị khóa).
  bool get _isGuest => RoleService().currentRole.value == AppRole.guest;

  // ── Trạng thái câu hỏi VIẾT chữ ──────────────────────────
  List<KanjiStroke> _strokes = [];
  int _strokeIndex = 0;
  List<List<Offset>> _userPaths = [];
  bool _strokesLoading = false;

  /// Hiện chữ mẫu mờ + số nét + mũi tên? Tắt = viết bằng trí nhớ.
  /// Giữ nguyên lựa chọn qua các câu (không reset mỗi chữ).
  bool _showGuides = true;

  // ── Trạng thái quiz ──────────────────────────────────────
  final List<Kana> _queue = [];
  int _poolSize = 0;
  Kana? _current;
  int _answered = 0;
  int _correct = 0;
  _Feedback _feedback = _Feedback.none;
  String _wrongAnswer = '';
  Timer? _advanceTimer;

  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();

  List<KanaRow> get _rows => _showKatakana ? kKatakanaRows : kHiraganaRows;
  Set<int> get _sel => _showKatakana ? _selKata : _selHira;

  int get _totalSelectedKana {
    int n = 0;
    for (final i in _selHira) {
      n += kHiraganaRows[i].kana.length;
    }
    for (final i in _selKata) {
      n += kKatakanaRows[i].kana.length;
    }
    return n;
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggleRow(int i) {
    setState(() {
      if (_sel.contains(i)) {
        _sel.remove(i);
      } else {
        _sel.add(i);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final all = _rows.length;
      if (_sel.length == all) {
        _sel.clear();
      } else {
        _sel
          ..clear()
          ..addAll(List.generate(all, (i) => i));
      }
    });
  }

  void _startQuiz() {
    final pool = <Kana>[];
    for (final i in _selHira) {
      pool.addAll(kHiraganaRows[i].kana);
    }
    for (final i in _selKata) {
      pool.addAll(kKatakanaRows[i].kana);
    }
    if (pool.isEmpty) return;
    pool.shuffle(_rng);

    setState(() {
      _queue
        ..clear()
        ..addAll(pool);
      _poolSize = pool.length;
      _current = _queue.first;
      _answered = 0;
      _correct = 0;
      _feedback = _Feedback.none;
      _input.clear();
      _phase = _Phase.quiz;
    });
    if (_writeMode) {
      _prepareWriteQuestion();
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  /// Tải nét mẫu cho chữ đang hỏi (chế độ VIẾT) và reset trạng thái canvas.
  Future<void> _prepareWriteQuestion() async {
    final kana = _current;
    if (kana == null) return;
    setState(() {
      _strokesLoading = true;
      _strokes = [];
      _strokeIndex = 0;
      _userPaths = [];
    });
    final strokes = await KanaStrokeLoader.load(kana.char);
    if (!mounted || _current != kana) return;
    setState(() {
      _strokes = strokes;
      _strokesLoading = false;
    });
  }

  /// Một nét vừa được viết ĐÚNG trên canvas.
  void _onStrokeCompleted(int index, List<Offset> path) {
    if (_feedback != _Feedback.none) return;
    setState(() {
      _userPaths = [..._userPaths, path];
      _strokeIndex = index + 1;
    });
    // Viết xong nét cuối → chữ hoàn thành, tính là ĐÚNG.
    if (_strokeIndex >= _strokes.length) {
      setState(() {
        _answered++;
        _correct++;
        _feedback = _Feedback.correct;
        _queue.removeAt(0);
      });
      _advanceTimer?.cancel();
      _advanceTimer = Timer(const Duration(milliseconds: 900), _nextQuestion);
    }
  }

  /// Viết lại chữ hiện tại từ nét đầu.
  void _resetWriting() {
    if (_feedback != _Feedback.none) return;
    setState(() {
      _strokeIndex = 0;
      _userPaths = [];
    });
  }

  /// Bỏ qua chữ đang viết: tính là SAI, đẩy xuống cuối hàng đợi hỏi lại.
  void _skipWrite() {
    if (_feedback != _Feedback.none || _current == null) return;
    setState(() {
      _answered++;
      _feedback = _Feedback.wrong;
      _wrongAnswer = _current!.char;
      _queue.add(_queue.removeAt(0));
    });
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 1200), _nextQuestion);
  }

  void _submit() {
    if (_feedback != _Feedback.none || _current == null) return;
    final value = _input.text;
    if (value.trim().isEmpty) return;
    final ok = _current!.matches(value);

    setState(() {
      _answered++;
      if (ok) {
        _correct++;
        _feedback = _Feedback.correct;
        _queue.removeAt(0); // thuộc rồi → bỏ khỏi hàng đợi
      } else {
        _feedback = _Feedback.wrong;
        _wrongAnswer = _current!.romaji;
        _queue.add(_queue.removeAt(0)); // đẩy xuống cuối để hỏi lại
      }
    });

    _advanceTimer?.cancel();
    _advanceTimer = Timer(
      Duration(milliseconds: ok ? 650 : 1500),
      _nextQuestion,
    );
  }

  void _nextQuestion() {
    if (!mounted) return;
    setState(() {
      _input.clear();
      _feedback = _Feedback.none;
      if (_queue.isEmpty) {
        _phase = _Phase.result;
        _current = null;
      } else {
        _current = _queue.first;
      }
    });
    if (_phase != _Phase.quiz) return;
    if (_writeMode) {
      _prepareWriteQuestion();
    } else {
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (_phase) {
          _Phase.setup => _buildSetup(),
          _Phase.quiz => _buildQuiz(),
          _Phase.result => _buildResult(),
        },
      ),
    );
  }

  // ── SETUP ────────────────────────────────────────────────
  Widget _buildSetup() {
    final allSelected = _sel.length == _rows.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Text('Học bảng chữ cái Kana',
                  style: AppTextStyles.latin(size: 19, weight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
        ),
        // Chọn chế độ luyện: gõ romaji (nhìn chữ → gõ) / viết chữ (nhìn romaji → viết)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: _modeTab('⌨️ Gõ romaji', !_writeMode, () => setState(() => _writeMode = false))),
                Expanded(
                  child: _modeTab(
                    _isGuest ? '✍️ Viết chữ 🔒' : '✍️ Viết chữ',
                    _writeMode,
                    () {
                      // Khách: khóa chế độ viết → mời đăng nhập.
                      if (_isGuest) {
                        showGuestLockDialog(context);
                        return;
                      }
                      setState(() => _writeMode = true);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Chuyển bảng Hiragana / Katakana
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Expanded(child: _tableTab('Hiragana', 'あ', !_showKatakana, () => setState(() => _showKatakana = false))),
              const SizedBox(width: 10),
              Expanded(child: _tableTab('Katakana', 'ア', _showKatakana, () => setState(() => _showKatakana = true))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chọn hàng để học',
                  style: AppTextStyles.latin(size: 13, weight: FontWeight.w700, color: AppColors.textMuted)),
              TextButton(
                onPressed: _toggleSelectAll,
                child: Text(allSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
                    style: AppTextStyles.latin(size: 13, weight: FontWeight.w700, color: AppColors.brandDark)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            itemCount: _rows.length,
            itemBuilder: (context, i) => _rowTile(i),
          ),
        ),
        _startBar(),
      ],
    );
  }

  Widget _modeTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active ? Border.all(color: AppColors.brand, width: 1.5) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.latin(
            size: 13.5,
            weight: FontWeight.w800,
            color: active ? AppColors.brandDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _tableTab(String label, String sample, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.brand : AppColors.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(sample, style: AppTextStyles.jp(size: 20, weight: FontWeight.w700, color: active ? Colors.white : AppColors.textSecondary)),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.latin(size: 15, weight: FontWeight.w800, color: active ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _rowTile(int i) {
    final row = _rows[i];
    final selected = _sel.contains(i);
    return GestureDetector(
      onTap: () => _toggleRow(i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceAlt : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.brand : AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.brand : AppColors.textFaint, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  for (final k in row.kana)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(k.char, style: AppTextStyles.jp(size: 22, weight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(k.romaji, style: AppTextStyles.latin(size: 10, color: AppColors.textMuted)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _startBar() {
    final count = _totalSelectedKana;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            count == 0 ? 'Chưa chọn hàng nào' : 'Đã chọn $count chữ',
            textAlign: TextAlign.center,
            style: AppTextStyles.latin(size: 14, weight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: count == 0 ? null : _startQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Bắt đầu', style: AppTextStyles.latin(size: 16, weight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── QUIZ ─────────────────────────────────────────────────
  Widget _buildQuiz() {
    final mastered = _poolSize - _queue.length;
    final progress = _poolSize == 0 ? 0.0 : mastered / _poolSize;
    final correct = _feedback == _Feedback.correct;
    final wrong = _feedback == _Feedback.wrong;

    final Color cardColor = correct
        ? AppColors.speaking.withValues(alpha: 0.12)
        : wrong
            ? AppColors.vocab.withValues(alpha: 0.10)
            : AppColors.surface;
    final Color cardBorder = correct
        ? AppColors.speaking
        : wrong
            ? AppColors.vocab
            : AppColors.border;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 20, 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                onPressed: () => setState(() => _phase = _Phase.setup),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$mastered/$_poolSize',
                  style: AppTextStyles.latin(size: 13, weight: FontWeight.w800, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _writeMode
                    ? _writeQuestionBody(cardColor, cardBorder)
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: cardBorder, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _current?.char ?? '',
                        style: AppTextStyles.jp(size: 96, weight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _input,
                      focusNode: _focus,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]'))],
                      onSubmitted: (_) => _submit(),
                      style: AppTextStyles.latin(size: 22, weight: FontWeight.w700, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Gõ romaji…',
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 24,
                      child: correct
                          ? Text('✓ Chính xác!',
                              style: AppTextStyles.latin(size: 15, weight: FontWeight.w800, color: AppColors.speaking))
                          : wrong
                              ? Text('✗ Đáp án: $_wrongAnswer',
                                  style: AppTextStyles.latin(size: 15, weight: FontWeight.w800, color: AppColors.vocab))
                              : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _feedback == _Feedback.none ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Kiểm tra', style: AppTextStyles.latin(size: 16, weight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Chữ đang hỏi thuộc bảng Katakana? (pool có thể trộn cả 2 bảng)
  bool get _currentIsKatakana {
    final c = _current?.char;
    if (c == null || c.isEmpty) return false;
    final cp = c.runes.first;
    return cp >= 0x30A0 && cp <= 0x30FF;
  }

  // ── Câu hỏi chế độ VIẾT: romaji → viết chữ lên canvas ────
  Widget _writeQuestionBody(Color cardColor, Color cardBorder) {
    final correct = _feedback == _Feedback.correct;
    final wrong = _feedback == _Feedback.wrong;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Đề bài: romaji + bảng cần viết.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder, width: 2),
          ),
          child: Column(
            children: [
              Text(
                _current?.romaji ?? '',
                style: AppTextStyles.latin(
                    size: 44, weight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              Text(
                'Viết chữ ${_currentIsKatakana ? 'Katakana' : 'Hiragana'}',
                style: AppTextStyles.latin(
                    size: 12, weight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Canvas viết chữ — chấm từng nét như luyện viết Kanji.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: _strokesLoading
              ? const AspectRatio(
                  aspectRatio: 1,
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.brand)),
                )
              : _strokes.isEmpty
                  ? AspectRatio(
                      aspectRatio: 1,
                      child: Center(
                        child: Text('Không tải được nét chữ mẫu.',
                            style: AppTextStyles.latin(
                                size: 13, color: AppColors.textMuted)),
                      ),
                    )
                  : KanjiWritingCanvas(
                      character: _current?.char ?? '',
                      strokes: _strokes,
                      activeStrokeIndex: _strokeIndex,
                      completedUserPaths: _userPaths,
                      onStrokeCompleted: _onStrokeCompleted,
                      showGuides: _showGuides,
                    ),
        ),
        const SizedBox(height: 10),
        // Tiến độ nét + nút bật/tắt gợi ý.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              child: correct
                  ? Text('✓ Chính xác! Đó là 「${_current?.char ?? ''}」',
                      style: AppTextStyles.latin(
                          size: 15,
                          weight: FontWeight.w800,
                          color: AppColors.speaking))
                  : wrong
                      ? Text('Chữ đúng là 「$_wrongAnswer」— sẽ hỏi lại sau!',
                          style: AppTextStyles.latin(
                              size: 14,
                              weight: FontWeight.w800,
                              color: AppColors.vocab))
                      : _strokes.isEmpty
                          ? const SizedBox.shrink()
                          : Text(
                              'Nét ${(_strokeIndex + 1).clamp(1, _strokes.length)}/${_strokes.length}',
                              style: AppTextStyles.latin(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: AppColors.textMuted)),
            ),
            if (_feedback == _Feedback.none) ...[
              const SizedBox(width: 12),
              // Tắt gợi ý → viết bằng trí nhớ (khó hơn, nhớ lâu hơn).
              GestureDetector(
                onTap: () => setState(() => _showGuides = !_showGuides),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showGuides
                        ? AppColors.surfaceAlt
                        : AppColors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _showGuides
                            ? AppColors.border
                            : AppColors.brand,
                        width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showGuides
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 14,
                        color: _showGuides
                            ? AppColors.textMuted
                            : AppColors.brandDark,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _showGuides ? 'Gợi ý: Bật' : 'Gợi ý: Tắt',
                        style: AppTextStyles.latin(
                          size: 11.5,
                          weight: FontWeight.w800,
                          color: _showGuides
                              ? AppColors.textMuted
                              : AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _feedback == _Feedback.none && _userPaths.isNotEmpty
                    ? _resetWriting
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.refresh_rounded,
                    size: 18, color: AppColors.textSecondary),
                label: Text('Viết lại',
                    style: AppTextStyles.latin(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _feedback == _Feedback.none ? _skipWrite : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.skip_next_rounded,
                    size: 18, color: AppColors.textSecondary),
                label: Text('Chưa nhớ',
                    style: AppTextStyles.latin(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── RESULT ───────────────────────────────────────────────
  Widget _buildResult() {
    final accuracy = _answered == 0 ? 0 : (_correct * 100 / _answered).round();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text('Hoàn thành!', style: AppTextStyles.latin(size: 24, weight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Bạn đã học xong $_poolSize chữ kana.',
              textAlign: TextAlign.center,
              style: AppTextStyles.latin(size: 14, color: AppColors.textMuted)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text('$accuracy%',
                    style: AppTextStyles.latin(size: 40, weight: FontWeight.w900, color: AppColors.speaking)),
                Text('độ chính xác ($_correct đúng / $_answered lượt)',
                    style: AppTextStyles.latin(size: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Học lại', style: AppTextStyles.latin(size: 16, weight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _phase = _Phase.setup),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Chọn lại',
                  style: AppTextStyles.latin(size: 15, weight: FontWeight.w700, color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

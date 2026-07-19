import 'dart:async';
import 'dart:math';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/services/data_repository.dart';
import '../../core/services/role_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/auth_screen.dart';
import 'kanji_data.dart';
import 'kanji_svg_parser.dart';
import 'kanji_writing_canvas.dart';
import '../../core/widgets/ai_tutor_bottom_sheet.dart';

class KanjiStudyScreen extends StatefulWidget {
  final KanjiData kanji;
  final int index;
  final int totalCount;
  final String lessonTitle;

  const KanjiStudyScreen({
    super.key,
    required this.kanji,
    required this.index,
    required this.totalCount,
    required this.lessonTitle,
  });

  @override
  State<KanjiStudyScreen> createState() => _KanjiStudyScreenState();
}

class _KanjiStudyScreenState extends State<KanjiStudyScreen> {
  int _selectedTab =
      0; // 0: Cách viết (Stroke order), 1: Ý nghĩa & Cách đọc, 2: Từ liên quan
  int _activeStrokeIndex = 0;
  List<List<Offset>> _completedUserPaths = [];
  bool _hasEarnedXpForThisKanji = false;

  String? _mnemonicStory;
  bool _isLoadingMnemonic = false;
  String? _mnemonicError;

  /// Mẹo viết sẵn cho các Kanji quen thuộc — hiện NGAY không cần mạng.
  /// Bấm 🔄 sẽ nhờ Gemini (qua Firebase AI Logic, không cần API key) sáng tác
  /// câu chuyện mới.
  static const Map<String, String> _localMnemonics = {
      '一': 'Hình ảnh một ngón tay chỉ ngang biểu thị số một.',
      '二': 'Hai ngạch ngang song song chồng lên nhau biểu thị số hai.',
      '三': 'Ba nét ngang xếp chồng đại diện cho số ba.',
      '人': 'Hình dáng một người đang sải bước chân đi bộ vững chãi. Hãy nhớ người phải đi bằng hai chân nhé! 🚶',
      '木': 'Hình ảnh một chiếc cây với thân đứng thẳng, cành lá dang ngang rộng mở và rễ cắm sâu xuống đất. 🌳',
      '水': 'Dòng nước chính chảy xiết ở giữa, hai bên là các giọt nước bắn tung tóe ra xung quanh. 💧',
      '火': 'Ngọn lửa đang bùng cháy dữ dội từ đống củi khô dưới đất, bắn ra tia lửa hai bên. 🔥',
      '山': 'Hình ảnh ba ngọn núi cao nhấp nhô đứng cạnh nhau vững chãi trước gió bão. 🏔️',
      '川': 'Dòng sông uốn lượn hiền hòa với ba dòng nước chảy song song cùng một hướng. 🌊',
      '日': 'Hình ảnh mặt trời tròn xoe (nay viết vuông lại) với một tia nắng chói chang chiếu ở giữa. ☀️',
      '月': 'Hình ảnh vầng trăng khuyết ban đêm lơ lửng, có hai đám mây trôi lướt ngang qua giữa. 🌙',
      '本': 'Chữ MỘC (cây) có thêm một nét gạch ngang ở dưới gốc chỉ phần rễ cây - nguồn cội, sách vở bắt đầu từ nguồn gốc. 📚',
      '金': 'Hình ảnh một chiếc mái nhà bảo vệ quặng vàng chôn dưới đất, có hai hạt vàng lấp lánh lộ ra. 🪙',
      '土': 'Mặt đất màu mỡ có một mầm cây đang nhú lên mạnh mẽ từ dưới lòng đất cát. 🌱',
      '子': 'Hình ảnh một đứa bé mới sinh quấn trong tã, hai tay dang rộng ra đòi bố mẹ ôm vào lòng. 👶',
      '女': 'Hình ảnh người phụ nữ đang quỳ gối khép nép, hai tay chắp lại dịu dàng theo kiểu truyền thống. 👩',
      '学': 'Đứa trẻ (TỬ - 子) đang ngồi học dưới mái nhà (MIÊN), trên đầu có ba chấm như ba tia sáng kiến thức tỏa xuống. 🏫',
      '先': 'Người đi TRƯỚC (TIÊN) là người có đôi chân chạy nhanh, phía trên là hình đất cát bụi tung bay. 🏃\u200d♂️',
      '生': 'Hình ảnh một mầm cây nhỏ vừa nhú lên và SINH trưởng mạnh mẽ từ mặt đất. 🌱',
      '何': 'Một NGƯỜI (NHÂN đứng - 亻) đang vác trên vai một vật có hình dáng giống miệng (KHẨU) hỏi: "Cái GÌ thế này?". ❓',
  };

  /// Lần đầu mở tab: hiện mẹo viết sẵn nếu có (tức thì, không cần mạng);
  /// không có thì nhờ AI sáng tác. Bấm 🔄 → luôn nhờ AI tạo câu chuyện MỚI.
  Future<void> _generateMnemonic({bool forceAi = false}) async {
    final char = widget.kanji.character;

    if (!forceAi && _localMnemonics.containsKey(char)) {
      setState(() {
        _mnemonicStory = _localMnemonics[char];
        _isLoadingMnemonic = false;
        _mnemonicError = null;
      });
      return;
    }

    setState(() {
      _isLoadingMnemonic = true;
      _mnemonicError = null;
    });

    // Gọi Gemini qua Firebase AI Logic — KHÔNG cần API key trong app
    // (giống phần Luyện nói: Firebase + App Check lo xác thực).
    try {
      final prompt = '''
Bạn là một giáo viên tiếng Nhật vui tính. Hãy tạo một câu chuyện liên tưởng ngắn, vui vẻ, hài hước và dễ nhớ để giúp người học ghi nhớ mặt chữ và cách viết của chữ Kanji sau:
- Chữ Kanji: "$char"
- Ý nghĩa: "${widget.kanji.meaning}"
- Cách đọc Onyomi: "${widget.kanji.onyomi}"
- Cách đọc Kunyomi: "${widget.kanji.kunyomi}"
- Âm Hán Việt: "${widget.kanji.hanViet}"

Hãy viết bằng Tiếng Việt, sử dụng phong cách sáng tạo (ví dụ liên tưởng các nét vẽ giống hình ảnh gì đó, hoặc ghép các bộ thủ cấu thành).
Tối đa 4 câu ngắn gọn. Trình bày đẹp mắt với icon sinh động.
Trả về nội dung văn bản trực tiếp, không chứa markdown hay định dạng ```.
''';

      final model = FirebaseAI.vertexAI().generativeModel(model: ApiConfig.model);
      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw Exception('Model không trả về nội dung');
      }
      if (!mounted) return;
      setState(() {
        _mnemonicStory = text;
        _isLoadingMnemonic = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMnemonic = false;
        // Có mẹo viết sẵn thì rơi về nó thay vì báo lỗi.
        if (_localMnemonics.containsKey(char)) {
          _mnemonicStory = _localMnemonics[char];
          _mnemonicError = null;
        } else {
          _mnemonicError =
              'Chưa tạo được mẹo nhớ (AI đang bận hoặc mất mạng). Bấm 🔄 thử lại nhé!';
        }
      });
    }
  }

  bool _isAnimating = false;
  Timer? _animationTimer;

  List<KanjiStroke>? _dynamicStrokes;
  bool _isLoadingStrokes = false;

  List<KanjiStroke> get _currentStrokes =>
      _dynamicStrokes ?? widget.kanji.strokes;

  @override
  void initState() {
    super.initState();
    _loadKanjiVgStrokes();
  }

  // Tải nét vẽ KanjiVG chuẩn từ jsDelivr CDN
  Future<void> _loadKanjiVgStrokes() async {
    final char = widget.kanji.character;
    if (char.isEmpty) return;

    setState(() {
      _isLoadingStrokes = true;
    });

    try {
      final codePoint = char.runes.first;
      final hexString = codePoint.toRadixString(16).padLeft(5, '0');
      final url =
          'https://cdn.jsdelivr.net/gh/KanjiVG/kanjivg@master/kanji/$hexString.svg';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load SVG: ${response.statusCode}');
      }
      final svgContent = response.body;

      // Tìm tất cả các thẻ <path ... d="..." />
      final pathRegex = RegExp(r'<path[^>]*\bd="([^"]+)"');
      final matches = pathRegex.allMatches(svgContent);

      final List<KanjiStroke> loadedStrokes = [];
      for (final match in matches) {
        final d = match.group(1);
        if (d != null) {
          final points = KanjiSvgParser.parsePathData(d);
          if (points.isNotEmpty) {
            loadedStrokes.add(KanjiStroke(points: points, svgPathData: d));
          }
        }
      }

      if (loadedStrokes.isNotEmpty && mounted) {
        setState(() {
          _dynamicStrokes = loadedStrokes;
          _isLoadingStrokes = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _dynamicStrokes = widget.kanji.strokes;
            _isLoadingStrokes = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading KanjiVG strokes for $char: $e');
      if (mounted) {
        setState(() {
          _dynamicStrokes = widget.kanji.strokes;
          _isLoadingStrokes = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  // Chạy tự động vẽ nét
  void _playStrokeAnimation() async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _completedUserPaths = [];
      _activeStrokeIndex = 0;
    });

    final totalStrokes = _currentStrokes.length;

    for (int i = 0; i <= totalStrokes; i++) {
      if (!mounted || !_isAnimating) return;
      setState(() {
        _activeStrokeIndex = i;
      });
      await Future.delayed(const Duration(milliseconds: 900));
    }

    if (mounted) {
      setState(() {
        _isAnimating = false;
        _activeStrokeIndex = 0; // Reset lại để người dùng tự viết
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _completedUserPaths = [];
      _activeStrokeIndex = 0;
      _isAnimating = false;
      _animationTimer?.cancel();
    });
  }

  void _undoLastStroke() {
    if (_completedUserPaths.isNotEmpty) {
      setState(() {
        _completedUserPaths.removeLast();
        _activeStrokeIndex = _completedUserPaths.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kanji = widget.kanji;
    final totalStrokes = _currentStrokes.length;
    final isGuest = RoleService().currentRole.value == AppRole.guest;
    final isWritingLocked = isGuest && !const {'才', '人', '私'}.contains(widget.kanji.character);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lessonTitle,
              style: AppTextStyles.latin(
                  size: 13,
                  color: AppColors.textMuted,
                  weight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.index + 1} / ${widget.totalCount} chữ trong bài',
              style: AppTextStyles.latin(size: 11, color: AppColors.textFaint),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kanji.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              '弟子 II',
              style: AppTextStyles.jp(
                  size: 11, color: AppColors.kanji, weight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── CARD TRÊN: Hiển thị chữ Hán lớn & Nút Xem nét ──────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Hán tự chính
                  Container(
                    width: 140,
                    height: 140,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Text(
                      kanji.character,
                      style: AppTextStyles.jp(
                          size: 84,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge nét
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFE9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalStrokes nét',
                          style: AppTextStyles.latin(
                              size: 13,
                              color: AppColors.textSecondary,
                              weight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút xem nét
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEDE7FA),
                          foregroundColor: AppColors.kanji,
                          elevation: 0,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _playStrokeAnimation,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(
                          _isAnimating ? 'Đang vẽ...' : 'Xem thứ tự nét',
                          style: AppTextStyles.latin(
                              size: 13, weight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── TAB BAR CHUYỂN ĐỔI CHẾ ĐỘ ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEAE4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, '書き順', 'Cách viết'),
                  _buildTabButton(1, '意味・読み', 'Ý nghĩa & Đọc'),
                  _buildTabButton(2, '関連語', 'Từ liên quan'),
                  _buildTabButton(3, '連想記憶', 'Mẹo nhớ chữ'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── PHẦN HIỂN THỊ CHI TIẾT THEO TAB ──────────────────────────────────────
            if (_selectedTab == 0)
              // TAB 0: TẬP VIẾT (Interactive Canvas)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thanh điều khiển nét vẽ
                  Row(
                    children: [
                      Text(
                        'Nét ${_isAnimating ? _activeStrokeIndex : min(_activeStrokeIndex + 1, totalStrokes)} / $totalStrokes',
                        style: AppTextStyles.latin(
                            size: 14,
                            color: AppColors.textPrimary,
                            weight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      // Dots hiển thị trạng thái các nét
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          children: List.generate(totalStrokes, (index) {
                            final isCompleted = index < _activeStrokeIndex;
                            final isActive = index == _activeStrokeIndex;
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? AppColors.kanji
                                    : isActive
                                        ? AppColors.kanji.withOpacity(0.5)
                                        : Colors.grey.shade300,
                              ),
                            );
                          }),
                        ),
                      ),
                      // Nút Hoàn tác
                      TextButton.icon(
                        onPressed: _completedUserPaths.isEmpty
                            ? null
                            : _undoLastStroke,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: Text('Hoàn tác',
                            style: AppTextStyles.latin(
                                size: 12, weight: FontWeight.w600)),
                      ),
                      // Nút Xoá
                      TextButton.icon(
                        onPressed: (_completedUserPaths.isEmpty &&
                                _activeStrokeIndex == 0)
                            ? null
                            : _clearCanvas,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text('Xóa',
                            style: AppTextStyles.latin(
                                size: 12, weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Canvas viết chữ
                  Stack(
                    children: [
                      KanjiWritingCanvas(
                        character: widget.kanji.character,
                        strokes: _currentStrokes,
                        activeStrokeIndex: _activeStrokeIndex,
                        completedUserPaths: _completedUserPaths,
                        isAnimating: _isAnimating,
                        onStrokeCompleted: (index, userPath) {
                          setState(() {
                            _completedUserPaths.add(userPath);
                            _activeStrokeIndex = index + 1;
                          });

                          // Nếu viết xong tất cả các nét
                          if (_activeStrokeIndex >= totalStrokes) {
                            final wasAlreadyEarned = _hasEarnedXpForThisKanji;
                            if (!_hasEarnedXpForThisKanji) {
                              _hasEarnedXpForThisKanji = true;
                              DataRepository().addXp(10);
                            }
                            Future.microtask(() => _showSuccessDialog(earnedXp: !wasAlreadyEarned));
                          }
                        },
                      ),
                      if (_isLoadingStrokes)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF8F5).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.kanji,
                              ),
                            ),
                          ),
                        ),
                      if (isWritingLocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF8F5).withOpacity(0.94),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline, color: AppColors.vocab, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  'Tập viết bị giới hạn',
                                  style: AppTextStyles.latin(size: 15, weight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Chế độ Khách chỉ cho phép tập viết các chữ Hán cơ bản như 才, Nhân, 私. Đăng ký tài khoản để mở khóa toàn bộ kho chữ Hán nhé!',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.latin(size: 12, color: AppColors.textSecondary, height: 1.4),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AuthScreen(startRegister: false)),
                                    );
                                  },
                                  child: const Text('Đăng nhập ngay'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              )
            else if (_selectedTab == 1)
              // TAB 1: Ý NGHĨA & CÁCH ĐỌC
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          kanji.character,
                          style: AppTextStyles.jp(
                              size: 40,
                              color: AppColors.kanji,
                              weight: FontWeight.bold),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Âm Hán Việt: ${kanji.hanViet}',
                              style: AppTextStyles.latin(
                                  size: 16,
                                  color: AppColors.textPrimary,
                                  weight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nghĩa: ${kanji.meaning}',
                              style: AppTextStyles.latin(
                                  size: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(
                        height: 24, color: AppColors.border, thickness: 1),
                    _buildInfoRow('Âm Hán (Onyomi)', kanji.onyomi),
                    const SizedBox(height: 12),
                    _buildInfoRow('Âm Nhật (Kunyomi)', kanji.kunyomi),
                  ],
                ),
              )
            else if (_selectedTab == 2)
              // TAB 2: TỪ LIÊN QUAN
              Column(
                children: kanji.examples.map((example) {
                  final split = example.split(':');
                  final word = split[0];
                  final meaning = split.length > 1 ? split[1] : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(
                          word,
                          style: AppTextStyles.jp(
                              size: 16,
                              color: AppColors.textPrimary,
                              weight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          meaning.trim(),
                          style: AppTextStyles.latin(
                              size: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              // TAB 3: MẸO NHỚ CHỮ (Mnemonics)
              _buildMnemonicsTab(),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.blueAccent,
      //   foregroundColor: Colors.white,
      //   tooltip: 'Hỏi Trợ lý AI',
      //   child: const Icon(Icons.psychology_rounded, size: 28),
      //   onPressed: () {
      //     AITutorBottomSheet.show(
      //       context,
      //       topic: widget.kanji.character,
      //       type: 'kanji',
      //     );
      //   },
      // ),
    );
  }

  Widget _buildTabButton(int index, String jpText, String viText) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
          if (index == 3 && _mnemonicStory == null && !_isLoadingMnemonic) {
            _generateMnemonic();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.kanji : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.kanji.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                jpText,
                style: AppTextStyles.jp(
                  size: 10,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  weight: FontWeight.bold,
                ),
              ),
              Text(
                viText,
                style: AppTextStyles.latin(
                  size: 11,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  weight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.latin(
              size: 12, color: AppColors.textFaint, weight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Text(
            value,
            style: AppTextStyles.jp(
                size: 15,
                color: AppColors.textPrimary,
                weight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog({required bool earnedXp}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'Xuất sắc!',
                style: AppTextStyles.latin(
                    size: 20,
                    color: AppColors.textPrimary,
                    weight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            earnedXp
                ? 'Bạn đã hoàn thành viết đúng chữ Hán "${widget.kanji.character}" theo đúng thứ tự các nét và nhận được +10 XP!'
                : 'Bạn đã hoàn thành viết đúng chữ Hán "${widget.kanji.character}" theo đúng thứ tự các nét!',
            style:
                AppTextStyles.latin(size: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearCanvas();
              },
              child: Text(
                'Luyện tập lại',
                style: AppTextStyles.latin(
                    size: 14,
                    color: AppColors.textMuted,
                    weight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kanji,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Đóng',
                style: AppTextStyles.latin(size: 14, weight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMnemonicsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 10),
              Text(
                'Mẹo liên tưởng Kanji',
                style: AppTextStyles.latin(
                  size: 16,
                  color: AppColors.textPrimary,
                  weight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_mnemonicStory != null && !_isLoadingMnemonic)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.kanji, size: 20),
                  tooltip: 'Nhờ AI sáng tác câu chuyện mới',
                  onPressed: () => _generateMnemonic(forceAi: true),
                ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border, thickness: 1),

          if (_isLoadingMnemonic)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.kanji),
                    SizedBox(height: 12),
                    Text('AI đang suy nghĩ câu chuyện cho bạn...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else if (_mnemonicError != null) ...[
            Text(
              _mnemonicError!,
              style: AppTextStyles.latin(size: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kanji,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _generateMnemonic(forceAi: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else if (_mnemonicStory != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8), // Soft pink/rose tint
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCE7F3)),
              ),
              child: Text(
                _mnemonicStory!,
                style: AppTextStyles.latin(
                  size: 14,
                  color: const Color(0xFF86198F), // Premium dark purple/rose color
                  height: 1.6,
                  weight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

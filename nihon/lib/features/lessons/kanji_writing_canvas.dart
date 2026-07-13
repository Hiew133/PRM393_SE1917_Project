import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'kanji_data.dart';
import 'kanji_svg_parser.dart';

class KanjiWritingCanvas extends StatefulWidget {
  final String character;
  final List<KanjiStroke> strokes;
  final int activeStrokeIndex;
  final Function(int completedIndex, List<Offset> userPath) onStrokeCompleted;
  final List<List<Offset>> completedUserPaths;
  final bool isAnimating;
  final VoidCallback? onClear;
  final VoidCallback? onUndo;

  const KanjiWritingCanvas({
    super.key,
    required this.character,
    required this.strokes,
    required this.activeStrokeIndex,
    required this.onStrokeCompleted,
    required this.completedUserPaths,
    this.isAnimating = false,
    this.onClear,
    this.onUndo,
  });

  @override
  State<KanjiWritingCanvas> createState() => _KanjiWritingCanvasState();
}

class _KanjiWritingCanvasState extends State<KanjiWritingCanvas> {
  List<Offset> _activeUserPath = [];
  bool _isDrawingValid = false;
  final GlobalKey _canvasKey = GlobalKey();

  List<Offset> _resamplePath(List<Offset> points, int n) {
    if (points.isEmpty) return [];
    if (points.length == 1) {
      return List.generate(n, (_) => points.first);
    }

    double totalLength = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalLength += (points[i + 1] - points[i]).distance;
    }

    double interval = totalLength / (n - 1);
    List<Offset> resampled = [points.first];
    double accumulated = 0.0;

    int i = 0;
    Offset current = points.first;

    while (i < points.length - 1) {
      double dist = (points[i + 1] - current).distance;
      if (accumulated + dist >= interval) {
        double t = dist == 0 ? 0.0 : (interval - accumulated) / dist;
        Offset nextPoint = Offset(
          current.dx + t * (points[i + 1].dx - current.dx),
          current.dy + t * (points[i + 1].dy - current.dy),
        );
        resampled.add(nextPoint);
        current = nextPoint;
        accumulated = 0.0;
      } else {
        accumulated += dist;
        i++;
        current = points[i];
      }
    }

    while (resampled.length < n) {
      resampled.add(points.last);
    }
    if (resampled.length > n) {
      resampled = resampled.sublist(0, n);
    }

    return resampled;
  }

  void _handleStart(Offset localPosition) {
    if (widget.activeStrokeIndex >= widget.strokes.length) return;

    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final canvasSize = renderBox.size;

    final templateStroke = widget.strokes[widget.activeStrokeIndex];

    // Chuyển đổi điểm bắt đầu template sang toạ độ canvas thực tế
    final templateStart = Offset(
      templateStroke.startPoint.dx * canvasSize.width,
      templateStroke.startPoint.dy * canvasSize.height,
    );

    // Kiểm tra nếu điểm chạm đầu tiên đủ gần điểm bắt đầu nét vẽ
    final distance = (localPosition - templateStart).distance;
    final tolerance = canvasSize.width * 0.18; // khoảng 54px trên canvas 300px

    if (distance <= tolerance) {
      setState(() {
        _activeUserPath = [localPosition];
        _isDrawingValid = true;
      });
    } else {
      setState(() {
        _activeUserPath = [];
        _isDrawingValid = false;
      });
    }
  }

  void _handleUpdate(Offset localPosition) {
    if (!_isDrawingValid) return;
    setState(() {
      _activeUserPath.add(localPosition);
    });
  }

  void _handleEnd() {
    if (!_isDrawingValid || _activeUserPath.isEmpty) return;

    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final canvasSize = renderBox.size;

    final templateStroke = widget.strokes[widget.activeStrokeIndex];

    // Chuyển đổi toàn bộ điểm của nét vẽ mẫu sang hệ toạ độ canvas thực tế
    final templatePoints = templateStroke.points
        .map((p) => Offset(p.dx * canvasSize.width, p.dy * canvasSize.height))
        .toList();

    bool isSuccess = false;

    if (_activeUserPath.length >= 2 && templatePoints.length >= 2) {
      // Kiểm tra khoảng cách điểm bắt đầu
      final startDistance =
          (_activeUserPath.first - templatePoints.first).distance;
      final startTolerance =
          canvasSize.width * 0.18; // khoảng 54px trên canvas 300px

      if (startDistance <= startTolerance) {
        // Resample cả nét vẽ người dùng và nét vẽ mẫu thành 16 điểm để so sánh hình dáng
        final resampledUser = _resamplePath(_activeUserPath, 16);
        final resampledTemplate = _resamplePath(templatePoints, 16);

        // Tính khoảng cách trung bình giữa các cặp điểm tương ứng
        double totalDistance = 0.0;
        for (int i = 0; i < 16; i++) {
          totalDistance += (resampledUser[i] - resampledTemplate[i]).distance;
        }
        final averageDistance = totalDistance / 16;

        // Ngưỡng chấp nhận: 15% chiều rộng canvas (khoảng 45px trên canvas 300px)
        final shapeThreshold = canvasSize.width * 0.15;

        if (averageDistance <= shapeThreshold) {
          isSuccess = true;
        }
      }
    }

    if (isSuccess) {
      // Thành công: Gửi đường dẫn người dùng vẽ lên kèm index
      widget.onStrokeCompleted(
        widget.activeStrokeIndex,
        List<Offset>.from(_activeUserPath),
      );
    }

    // Reset nét vẽ hiện tại của ngón tay
    setState(() {
      _activeUserPath = [];
      _isDrawingValid = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          // Listener (pointer thô) để lấy toạ độ vẽ; RawGestureDetector với
          // EagerGestureRecognizer để canvas THẮNG gesture arena ngay khi đặt
          // bút → SingleChildScrollView cha không cướp cử chỉ kéo DỌC, nhờ vậy
          // vẽ được nét dọc/xuống.
          child: Listener(
            key: _canvasKey,
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => _handleStart(event.localPosition),
            onPointerMove: (event) => _handleUpdate(event.localPosition),
            onPointerUp: (event) => _handleEnd(),
            onPointerCancel: (event) => _handleEnd(),
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: <Type, GestureRecognizerFactory>{
                EagerGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                  (EagerGestureRecognizer instance) {},
                ),
              },
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: _KanjiPainter(
                    character: widget.character,
                    strokes: widget.strokes,
                    activeStrokeIndex: widget.activeStrokeIndex,
                    completedUserPaths: widget.completedUserPaths,
                    activeUserPath: _activeUserPath,
                    isAnimating: widget.isAnimating,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KanjiPainter extends CustomPainter {
  final String character;
  final List<KanjiStroke> strokes;
  final int activeStrokeIndex;
  final List<List<Offset>> completedUserPaths;
  final List<Offset> activeUserPath;
  final bool isAnimating;

  _KanjiPainter({
    required this.character,
    required this.strokes,
    required this.activeStrokeIndex,
    required this.completedUserPaths,
    required this.activeUserPath,
    required this.isAnimating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawKanjiTemplate(canvas, size);
    _drawCompletedStrokes(canvas, size);
    _drawActiveUserPath(canvas);
    _drawGuides(canvas, size);
  }

  // 1. Vẽ ô lưới nền ô vuông đứt nét
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vẽ đường bao quanh và phân chia ô lưới chính
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Vẽ nét đứt chéo để hỗ trợ định vị nét vẽ (giống sách tập viết)
    const dashWidth = 5.0;
    const dashSpace = 5.0;

    void drawDashedLine(Offset p1, Offset p2) {
      double dx = p2.dx - p1.dx;
      double dy = p2.dy - p1.dy;
      double distance = sqrt(dx * dx + dy * dy);
      int count = (distance / (dashWidth + dashSpace)).floor();
      for (int i = 0; i < count; i++) {
        double percentStart = (i * (dashWidth + dashSpace)) / distance;
        double percentEnd =
            (i * (dashWidth + dashSpace) + dashWidth) / distance;
        canvas.drawLine(
          Offset(p1.dx + dx * percentStart, p1.dy + dy * percentStart),
          Offset(p1.dx + dx * percentEnd, p1.dy + dy * percentEnd),
          dashPaint,
        );
      }
    }

    drawDashedLine(Offset.zero, Offset(size.width, size.height));
    drawDashedLine(Offset(size.width, 0), Offset(0, size.height));
  }

  void _drawStroke(Canvas canvas, Size size, KanjiStroke stroke, Paint paint) {
    if (stroke.svgPathData != null && stroke.svgPathData!.isNotEmpty) {
      final path = KanjiSvgParser.parsePath(stroke.svgPathData!, size);
      canvas.drawPath(path, paint);
      return;
    }

    final path = Path();
    final points = stroke.points;
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx * size.width, points.first.dy * size.height);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx * size.width, points[i].dy * size.height);
      }
    }
    canvas.drawPath(path, paint);
  }

  // 2. Vẽ chữ mẫu Hán tự mờ mờ ở nền (dùng nét vẽ chuẩn từ SVG/vector)
  void _drawKanjiTemplate(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFECE7DF)
      ..strokeWidth = 24.0 // Độ dày nét mẫu mờ phù hợp để dễ tô theo
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, size, stroke, paint);
    }
  }

  // 3. Vẽ các nét người dùng đã viết hoàn thành thành công
  void _drawCompletedStrokes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.kanji
      ..strokeWidth = 20.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (isAnimating) {
      for (int i = 0; i < activeStrokeIndex; i++) {
        _drawStroke(canvas, size, strokes[i], paint);
      }
    } else {
      // Thay vì vẽ nét ngoằn ngoèo của người dùng, ta vẽ các nét mẫu tương ứng đã được hoàn thành.
      // Điều này giúp nét vẽ của người dùng sau khi hoàn tất sẽ "snap" khớp hoàn hảo và thẳng hàng với chữ mẫu.
      final completedCount = completedUserPaths.length;
      for (int i = 0; i < completedCount; i++) {
        if (i >= strokes.length) break;
        _drawStroke(canvas, size, strokes[i], paint);
      }
    }
  }

  // 4. Vẽ nét người dùng đang rê ngón tay vẽ
  void _drawActiveUserPath(Canvas canvas) {
    if (activeUserPath.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.kanji.withOpacity(0.6)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(activeUserPath.first.dx, activeUserPath.first.dy);
    for (int i = 1; i < activeUserPath.length; i++) {
      path.lineTo(activeUserPath[i].dx, activeUserPath[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  // 5. Vẽ gợi ý hướng viết (Số thứ tự nét + Mũi tên) cho nét đang kích hoạt
  void _drawGuides(Canvas canvas, Size size) {
    if (activeStrokeIndex >= strokes.length) return;

    final stroke = strokes[activeStrokeIndex];
    if (stroke.points.length < 2) return;

    final start = Offset(
        stroke.startPoint.dx * size.width, stroke.startPoint.dy * size.height);
    final next = Offset(
        stroke.points[1].dx * size.width, stroke.points[1].dy * size.height);

    // Vẽ vòng tròn số thứ tự nét
    final circlePaint = Paint()
      ..color = AppColors.kanji
      ..style = PaintingStyle.fill;

    final circleBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(start, 12.0, circlePaint);
    canvas.drawCircle(start, 12.0, circleBorderPaint);

    // Vẽ chữ số nét
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${activeStrokeIndex + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      start - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    // Vẽ mũi tên hướng đi của nét
    final direction = next - start;
    final angle = atan2(direction.dy, direction.dx);

    // Điểm hiển thị mũi tên: đặt cách điểm bắt đầu khoảng 30px theo hướng vẽ
    final arrowPos = start + Offset.fromDirection(angle, 35.0);

    final arrowPaint = Paint()
      ..color = AppColors.kanji
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Vẽ thân mũi tên mỏng chỉ hướng
    final arrowLength = 14.0;
    final arrowEnd = arrowPos + Offset.fromDirection(angle, arrowLength);
    canvas.drawLine(arrowPos, arrowEnd, arrowPaint);

    // Vẽ hai cánh đầu mũi tên
    final arrowHeadAngle = pi / 6; // 30 độ
    final leftWing =
        arrowEnd - Offset.fromDirection(angle - arrowHeadAngle, 6.0);
    final rightWing =
        arrowEnd - Offset.fromDirection(angle + arrowHeadAngle, 6.0);
    canvas.drawLine(arrowEnd, leftWing, arrowPaint);
    canvas.drawLine(arrowEnd, rightWing, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _KanjiPainter oldDelegate) {
    return oldDelegate.activeStrokeIndex != activeStrokeIndex ||
        oldDelegate.completedUserPaths.length != completedUserPaths.length ||
        oldDelegate.activeUserPath.length != activeUserPath.length ||
        oldDelegate.isAnimating != isAnimating;
  }
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Nhân vật ảo 2D「さくら先生」— vẽ hoàn toàn bằng CustomPainter (không cần
/// file ảnh), theo Hướng 1 "sprite-swap kiểu game VN":
///
/// - **Lip-sync đơn giản:** trong lúc TTS đang phát ([speaking] = true), miệng
///   đảo vòng qua 4 khẩu hình (đóng / mở nhỏ / mở to / dẹt kiểu え) ~9 hình/s,
///   giống cách visual novel làm thoại nhân vật. TTS dừng → miệng khép lại.
/// - **Idle:** đầu nhún nhẹ theo sin, mắt chớp ~3.4s/lần.
/// - **[listening]:** mắt cười khép cong, má ửng hồng, đầu nghiêng nhẹ.
/// - **[thinking]:** mắt liếc lên, miệng chúm "o" nhỏ (đang suy nghĩ).
class AiCharacter extends StatefulWidget {
  final bool speaking;
  final bool listening;
  final bool thinking;
  final double size;

  const AiCharacter({
    super.key,
    this.speaking = false,
    this.listening = false,
    this.thinking = false,
    this.size = 72,
  });

  @override
  State<AiCharacter> createState() => _AiCharacterState();
}

class _AiCharacterState extends State<AiCharacter>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// Thời gian chạy (giây) — nguồn cho mọi animation, painter tự nghe qua
  /// `repaint:` nên KHÔNG cần setState mỗi frame.
  final ValueNotifier<double> _time = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMilliseconds / 1000.0;
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _SakuraSenseiPainter(
          time: _time,
          speaking: widget.speaking,
          listening: widget.listening,
          thinking: widget.thinking,
        ),
      ),
    );
  }
}

class _SakuraSenseiPainter extends CustomPainter {
  final ValueListenable<double> time;
  final bool speaking;
  final bool listening;
  final bool thinking;

  _SakuraSenseiPainter({
    required this.time,
    required this.speaking,
    required this.listening,
    required this.thinking,
  }) : super(repaint: time);

  // Bảng màu nhân vật (hợp tông ấm của app さくら).
  static const _hair = Color(0xFF6B4A32);
  static const _hairDark = Color(0xFF57391F);
  static const _skin = Color(0xFFFFE9CE);
  static const _skinEdge = Color(0xFFEECBA4);
  static const _eye = Color(0xFF3A2A1C);
  static const _blush = Color(0xFFFF9EB5);
  static const _mouthIn = Color(0xFF8C4534);
  static const _tongue = Color(0xFFE58A78);
  static const _petal = Color(0xFFFFA8C0);

  /// Vòng khẩu hình khi đang nói: 0 khép · 1 mở nhỏ · 2 mở to · 3 dẹt (え).
  static const _mouthLoop = [1, 2, 1, 3, 2, 1, 3, 0, 2, 1];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final s = size.width / 100;
    canvas.scale(s);

    // Đầu nhún nhẹ; nói thì nhún nhanh hơn một chút cho "có hồn".
    double bob = math.sin(t * 2 * math.pi / 2.6) * 1.6;
    if (speaking) bob += math.sin(t * 2 * math.pi / 0.55) * 0.7;
    // Nghiêng đầu khi đang lắng nghe.
    final tilt =
        listening ? 0.07 + math.sin(t * 2 * math.pi / 2.2) * 0.02 : 0.0;

    canvas.translate(50, 52 + bob);
    canvas.rotate(tilt);
    canvas.translate(-50, -52);

    _paintBackHair(canvas);
    _paintFace(canvas);
    _paintBangs(canvas);
    _paintBlush(canvas);
    _paintEyes(canvas, t);
    _paintMouth(canvas, t);
    _paintSakuraPin(canvas);
  }

  void _paintBackHair(Canvas c) {
    final p = Paint()..color = _hairDark;
    // Khối tóc sau đầu + hai lọn tóc hai bên.
    c.drawOval(Rect.fromCenter(
        center: const Offset(50, 50), width: 66, height: 62), p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(15, 44, 12, 36), const Radius.circular(6)),
        p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(73, 44, 12, 36), const Radius.circular(6)),
        p);
  }

  void _paintFace(Canvas c) {
    final face = Rect.fromCenter(
        center: const Offset(50, 58), width: 56, height: 52);
    c.drawOval(face, Paint()..color = _skin);
    c.drawOval(
        face,
        Paint()
          ..color = _skinEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  void _paintBangs(Canvas c) {
    final p = Paint()..color = _hair;
    // Mái tóc phủ trán, mép dưới lượn sóng 3 múi.
    final path = Path()
      ..moveTo(21, 60)
      ..quadraticBezierTo(16, 24, 50, 21)
      ..quadraticBezierTo(84, 24, 79, 60)
      ..quadraticBezierTo(73, 48, 66, 57)
      ..quadraticBezierTo(59, 42, 50, 51)
      ..quadraticBezierTo(41, 42, 34, 57)
      ..quadraticBezierTo(27, 48, 21, 60)
      ..close();
    c.drawPath(path, p);
    // Cọng tóc "ahoge" vểnh trên đỉnh đầu.
    final ahoge = Path()
      ..moveTo(50, 22)
      ..quadraticBezierTo(54, 12, 60, 14);
    c.drawPath(
        ahoge,
        Paint()
          ..color = _hair
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round);
  }

  void _paintBlush(Canvas c) {
    // Má ửng hơn khi đang lắng nghe người học nói.
    final p = Paint()
      ..color = _blush.withValues(alpha: listening ? 0.55 : 0.32);
    c.drawOval(
        Rect.fromCenter(center: const Offset(33, 70), width: 9, height: 5), p);
    c.drawOval(
        Rect.fromCenter(center: const Offset(67, 70), width: 9, height: 5), p);
  }

  void _paintEyes(Canvas c, double t) {
    const lx = 39.0, rx = 61.0;
    // Suy nghĩ → liếc mắt lên trên một chút.
    final ey = thinking ? 61.0 : 62.5;

    if (listening) {
      // Mắt cười khép cong (^ ^) — đang chăm chú nghe.
      final p = Paint()
        ..color = _eye
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      c.drawPath(
          Path()
            ..moveTo(lx - 4.5, ey + 1)
            ..quadraticBezierTo(lx, ey - 3.5, lx + 4.5, ey + 1),
          p);
      c.drawPath(
          Path()
            ..moveTo(rx - 4.5, ey + 1)
            ..quadraticBezierTo(rx, ey - 3.5, rx + 4.5, ey + 1),
          p);
      return;
    }

    // Chớp mắt ~3.4s một lần, mỗi lần 0.13s.
    const period = 3.4, blinkDur = 0.13;
    final phase = t % period;
    double open = 1;
    if (phase < blinkDur) {
      open = (1 - math.sin(phase / blinkDur * math.pi)).clamp(0.08, 1.0);
    }

    final eyeP = Paint()..color = _eye;
    for (final x in [lx, rx]) {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(x, ey), width: 8, height: 10.5 * open),
          eyeP);
      if (open > 0.5) {
        // Ánh sáng trong mắt cho sinh động.
        c.drawCircle(Offset(x + 1.8, ey - 2.2 * open), 1.5,
            Paint()..color = Colors.white);
        c.drawCircle(Offset(x - 1.6, ey + 1.6 * open), 0.8,
            Paint()..color = Colors.white70);
      }
    }
    // Lông mày.
    final brow = Paint()
      ..color = _hairDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final browLift = thinking ? -1.5 : 0.0;
    c.drawPath(
        Path()
          ..moveTo(lx - 4.5, 54 + browLift)
          ..quadraticBezierTo(lx, 52 + browLift, lx + 4.5, 53.5 + browLift),
        brow);
    c.drawPath(
        Path()
          ..moveTo(rx - 4.5, 53.5 + browLift)
          ..quadraticBezierTo(rx, 52 + browLift, rx + 4.5, 54 + browLift),
        brow);
  }

  void _paintMouth(Canvas c, double t) {
    const cx = 50.0, cy = 77.0;

    int shape;
    if (speaking) {
      // Sprite-swap: đảo khẩu hình ~9 hình/giây theo vòng lặp có sẵn.
      shape = _mouthLoop[(t / 0.11).floor() % _mouthLoop.length];
    } else if (thinking) {
      shape = 4; // chúm "o" nhỏ
    } else {
      shape = 0; // mỉm cười khép
    }

    switch (shape) {
      case 0: // cười khép
        c.drawPath(
            Path()
              ..moveTo(cx - 5, cy - 1)
              ..quadraticBezierTo(cx, cy + 2.5, cx + 5, cy - 1),
            Paint()
              ..color = _mouthIn
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round);
      case 1: // mở nhỏ (あ nhẹ)
        c.drawOval(
            Rect.fromCenter(
                center: const Offset(cx, cy), width: 7, height: 5.5),
            Paint()..color = _mouthIn);
      case 2: // mở to (あ)
        final r = Rect.fromCenter(
            center: const Offset(cx, cy + 1), width: 11, height: 9.5);
        c.drawOval(r, Paint()..color = _mouthIn);
        c.drawOval(
            Rect.fromCenter(
                center: const Offset(cx, cy + 3.5), width: 7, height: 3.5),
            Paint()..color = _tongue);
      case 3: // dẹt (え/い)
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: const Offset(cx, cy), width: 10, height: 4),
                const Radius.circular(2)),
            Paint()..color = _mouthIn);
      case 4: // chúm "o" (đang suy nghĩ)
        c.drawCircle(const Offset(cx, cy), 2.4, Paint()..color = _mouthIn);
    }
  }

  void _paintSakuraPin(Canvas c) {
    // Kẹp tóc hoa sakura bên mái phải.
    const center = Offset(69, 35);
    final petal = Paint()..color = _petal;
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5 - math.pi / 2;
      c.drawCircle(
          center + Offset(math.cos(a) * 3.2, math.sin(a) * 3.2), 2.4, petal);
    }
    c.drawCircle(center, 1.6, Paint()..color = const Color(0xFFFFE082));
  }

  @override
  bool shouldRepaint(_SakuraSenseiPainter old) =>
      old.speaking != speaking ||
      old.listening != listening ||
      old.thinking != thinking;
}

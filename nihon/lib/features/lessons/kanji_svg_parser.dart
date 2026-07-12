import 'dart:ui';

class KanjiSvgParser {
  static const double viewBoxSize = 109.0;

  static Path parsePath(String d, Size size) {
    final path = Path();
    final tokens = _tokenize(d);

    double currentX = 0.0;
    double currentY = 0.0;
    double startX = 0.0;
    double startY = 0.0;
    double lastControlX = 0.0;
    double lastControlY = 0.0;

    int i = 0;
    String cmd = '';

    bool isCommand(String token) => RegExp(r'^[MmLlHhVvCcSsQqTtZz]$').hasMatch(token);

    double parseNextNum() {
      if (i >= tokens.length) return 0.0;
      return double.tryParse(tokens[i++]) ?? 0.0;
    }

    Offset scale(double x, double y) {
      return Offset(x / viewBoxSize * size.width, y / viewBoxSize * size.height);
    }

    while (i < tokens.length) {
      final token = tokens[i];
      if (isCommand(token)) {
        cmd = token;
        i++;
        if (cmd == 'Z' || cmd == 'z') {
          path.close();
          currentX = startX;
          currentY = startY;
        }
        continue;
      }

      if (cmd == 'M') {
        currentX = parseNextNum();
        currentY = parseNextNum();
        startX = currentX;
        startY = currentY;
        final p = scale(currentX, currentY);
        path.moveTo(p.dx, p.dy);
        cmd = 'L';
      } else if (cmd == 'm') {
        currentX += parseNextNum();
        currentY += parseNextNum();
        startX = currentX;
        startY = currentY;
        final p = scale(currentX, currentY);
        path.moveTo(p.dx, p.dy);
        cmd = 'l';
      } else if (cmd == 'L') {
        currentX = parseNextNum();
        currentY = parseNextNum();
        final p = scale(currentX, currentY);
        path.lineTo(p.dx, p.dy);
      } else if (cmd == 'l') {
        currentX += parseNextNum();
        currentY += parseNextNum();
        final p = scale(currentX, currentY);
        path.lineTo(p.dx, p.dy);
      } else if (cmd == 'H') {
        currentX = parseNextNum();
        final p = scale(currentX, currentY);
        path.lineTo(p.dx, p.dy);
      } else if (cmd == 'h') {
        currentX += parseNextNum();
        final p = scale(currentX, currentY);
        path.lineTo(p.dx, p.dy);
      } else if (cmd == 'V') {
        currentY = parseNextNum();
        final p = scale(currentX, currentY);
        path.lineTo(p.dx, p.dy);
      } else if (cmd == 'v') {
        currentY += parseNextNum();
        final p = scale(currentX, currentY);
        path.lineTo(p.dx, p.dy);
      } else if (cmd == 'C') {
        final x1 = parseNextNum();
        final y1 = parseNextNum();
        final x2 = parseNextNum();
        final y2 = parseNextNum();
        final x = parseNextNum();
        final y = parseNextNum();
        final p1 = scale(x1, y1);
        final p2 = scale(x2, y2);
        final p = scale(x, y);
        path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p.dx, p.dy);
        currentX = x;
        currentY = y;
        lastControlX = x2;
        lastControlY = y2;
      } else if (cmd == 'c') {
        final x1 = currentX + parseNextNum();
        final y1 = currentY + parseNextNum();
        final x2 = currentX + parseNextNum();
        final y2 = currentY + parseNextNum();
        final x = currentX + parseNextNum();
        final y = currentY + parseNextNum();
        final p1 = scale(x1, y1);
        final p2 = scale(x2, y2);
        final p = scale(x, y);
        path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p.dx, p.dy);
        currentX = x;
        currentY = y;
        lastControlX = x2;
        lastControlY = y2;
      } else if (cmd == 'S') {
        final x1 = 2 * currentX - lastControlX;
        final y1 = 2 * currentY - lastControlY;
        final x2 = parseNextNum();
        final y2 = parseNextNum();
        final x = parseNextNum();
        final y = parseNextNum();
        final p1 = scale(x1, y1);
        final p2 = scale(x2, y2);
        final p = scale(x, y);
        path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p.dx, p.dy);
        currentX = x;
        currentY = y;
        lastControlX = x2;
        lastControlY = y2;
      } else if (cmd == 's') {
        final x1 = 2 * currentX - lastControlX;
        final y1 = 2 * currentY - lastControlY;
        final x2 = currentX + parseNextNum();
        final y2 = currentY + parseNextNum();
        final x = currentX + parseNextNum();
        final y = currentY + parseNextNum();
        final p1 = scale(x1, y1);
        final p2 = scale(x2, y2);
        final p = scale(x, y);
        path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p.dx, p.dy);
        currentX = x;
        currentY = y;
        lastControlX = x2;
        lastControlY = y2;
      } else if (cmd == 'Q') {
        final x1 = parseNextNum();
        final y1 = parseNextNum();
        final x = parseNextNum();
        final y = parseNextNum();
        final p1 = scale(x1, y1);
        final p = scale(x, y);
        path.quadraticBezierTo(p1.dx, p1.dy, p.dx, p.dy);
        currentX = x;
        currentY = y;
        lastControlX = x1;
        lastControlY = y1;
      } else if (cmd == 'q') {
        final x1 = currentX + parseNextNum();
        final y1 = currentY + parseNextNum();
        final x = currentX + parseNextNum();
        final y = currentY + parseNextNum();
        final p1 = scale(x1, y1);
        final p = scale(x, y);
        path.quadraticBezierTo(p1.dx, p1.dy, p.dx, p.dy);
        currentX = x;
        currentY = y;
        lastControlX = x1;
        lastControlY = y1;
      } else {
        i++;
      }
    }

    return path;
  }

  static List<Offset> parsePathData(String d) {
    final List<Offset> points = [];
    final tokens = _tokenize(d);
    
    double currentX = 0.0;
    double currentY = 0.0;
    
    // For smooth curves reflection
    double lastControlX = 0.0;
    double lastControlY = 0.0;
    
    int i = 0;
    String cmd = '';
    
    double parseNextNum() {
      if (i >= tokens.length) return 0.0;
      return double.tryParse(tokens[i++]) ?? 0.0;
    }
    
    while (i < tokens.length) {
      final token = tokens[i];
      if (RegExp(r'[MmLlHhVvCcSsQqTtAaZz]').hasMatch(token)) {
        cmd = token;
        i++;
        continue;
      }
      
      if (cmd == 'M') {
        final x = parseNextNum();
        final y = parseNextNum();
        currentX = x;
        currentY = y;
        points.add(Offset(currentX / viewBoxSize, currentY / viewBoxSize));
        cmd = 'L'; // Implicit L commands follow after M
      } else if (cmd == 'm') {
        final dx = parseNextNum();
        final dy = parseNextNum();
        currentX += dx;
        currentY += dy;
        points.add(Offset(currentX / viewBoxSize, currentY / viewBoxSize));
        cmd = 'l';
      } else if (cmd == 'L') {
        final x = parseNextNum();
        final y = parseNextNum();
        currentX = x;
        currentY = y;
        points.add(Offset(currentX / viewBoxSize, currentY / viewBoxSize));
      } else if (cmd == 'l') {
        final dx = parseNextNum();
        final dy = parseNextNum();
        currentX += dx;
        currentY += dy;
        points.add(Offset(currentX / viewBoxSize, currentY / viewBoxSize));
      } else if (cmd == 'H') {
        final x = parseNextNum();
        currentX = x;
        points.add(Offset(currentX / viewBoxSize, currentY / viewBoxSize));
      } else if (cmd == 'h') {
        final dx = parseNextNum();
        currentX += dx;
        points.add(Offset(currentX / viewBoxSize, currentY / viewBoxSize));
      } else if (cmd == 'V') {
        final y = parseNextNum();
        currentY = y;
        points.add(Offset(currentX / viewBoxSize, currentY / viewBoxSize));
      } else if (cmd == 'v') {
        final dy = parseNextNum();
        currentY += dy;
        points.add(Offset(currentX / viewBoxSize, currentY / viewBoxSize));
      } else if (cmd == 'C') {
        final x1 = parseNextNum();
        final y1 = parseNextNum();
        final x2 = parseNextNum();
        final y2 = parseNextNum();
        final x = parseNextNum();
        final y = parseNextNum();
        
        final p0 = Offset(currentX, currentY);
        final p1 = Offset(x1, y1);
        final p2 = Offset(x2, y2);
        final p3 = Offset(x, y);
        
        // Sample 4 points along the curve
        for (int step = 1; step <= 4; step++) {
          final t = step / 4.0;
          final sampled = _sampleCubicBezier(p0, p1, p2, p3, t);
          points.add(Offset(sampled.dx / viewBoxSize, sampled.dy / viewBoxSize));
        }
        
        currentX = x;
        currentY = y;
        lastControlX = x2;
        lastControlY = y2;
      } else if (cmd == 'c') {
        final dx1 = parseNextNum();
        final dy1 = parseNextNum();
        final dx2 = parseNextNum();
        final dy2 = parseNextNum();
        final dx = parseNextNum();
        final dy = parseNextNum();
        
        final p0 = Offset(currentX, currentY);
        final p1 = Offset(currentX + dx1, currentY + dy1);
        final p2 = Offset(currentX + dx2, currentY + dy2);
        final p3 = Offset(currentX + dx, currentY + dy);
        
        for (int step = 1; step <= 4; step++) {
          final t = step / 4.0;
          final sampled = _sampleCubicBezier(p0, p1, p2, p3, t);
          points.add(Offset(sampled.dx / viewBoxSize, sampled.dy / viewBoxSize));
        }
        
        lastControlX = currentX + dx2;
        lastControlY = currentY + dy2;
        currentX += dx;
        currentY += dy;
      } else if (cmd == 'S') {
        final x2 = parseNextNum();
        final y2 = parseNextNum();
        final x = parseNextNum();
        final y = parseNextNum();
        
        final p0 = Offset(currentX, currentY);
        final p1 = Offset(2 * currentX - lastControlX, 2 * currentY - lastControlY);
        final p2 = Offset(x2, y2);
        final p3 = Offset(x, y);
        
        for (int step = 1; step <= 4; step++) {
          final t = step / 4.0;
          final sampled = _sampleCubicBezier(p0, p1, p2, p3, t);
          points.add(Offset(sampled.dx / viewBoxSize, sampled.dy / viewBoxSize));
        }
        
        currentX = x;
        currentY = y;
        lastControlX = x2;
        lastControlY = y2;
      } else if (cmd == 's') {
        final dx2 = parseNextNum();
        final dy2 = parseNextNum();
        final dx = parseNextNum();
        final dy = parseNextNum();
        
        final p0 = Offset(currentX, currentY);
        final p1 = Offset(2 * currentX - lastControlX, 2 * currentY - lastControlY);
        final p2 = Offset(currentX + dx2, currentY + dy2);
        final p3 = Offset(currentX + dx, currentY + dy);
        
        for (int step = 1; step <= 4; step++) {
          final t = step / 4.0;
          final sampled = _sampleCubicBezier(p0, p1, p2, p3, t);
          points.add(Offset(sampled.dx / viewBoxSize, sampled.dy / viewBoxSize));
        }
        
        lastControlX = currentX + dx2;
        lastControlY = currentY + dy2;
        currentX += dx;
        currentY += dy;
      } else if (cmd == 'Z' || cmd == 'z') {
        if (points.isNotEmpty) {
          points.add(points.first);
        }
        break;
      } else {
        i++;
      }
    }
    
    // Deduplicate consecutive points
    final List<Offset> cleanPoints = [];
    for (final pt in points) {
      if (cleanPoints.isEmpty || (pt - cleanPoints.last).distance > 0.001) {
        cleanPoints.add(pt);
      }
    }
    
    return cleanPoints;
  }

  static List<String> _tokenize(String d) {
    final regex = RegExp(r'([MmLlHhVvCcSsQqTtZz])|(-?\d*\.?\d+(?:[eE][-+]?\d+)?)');
    return regex.allMatches(d).map((match) => match.group(0)!).toList();
  }

  static Offset _sampleCubicBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1.0 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    return Offset(
      uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx,
      uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy,
    );
  }
}

// Kiểm tra loader nét chữ kana đọc được SVG bundle trong assets và parse ra
// đúng số nét chuẩn (theo KanjiVG).

import 'package:flutter_test/flutter_test.dart';

import 'package:nihon/features/kana_quiz/kana_stroke_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('あ có 3 nét, し có 1 nét, ア có 2 nét', () async {
    expect((await KanaStrokeLoader.load('あ')).length, 3);
    expect((await KanaStrokeLoader.load('し')).length, 1);
    expect((await KanaStrokeLoader.load('ア')).length, 2);
  });

  test('mọi nét đều có điểm chuẩn hóa trong khoảng 0..1', () async {
    final strokes = await KanaStrokeLoader.load('ん');
    expect(strokes, isNotEmpty);
    for (final s in strokes) {
      expect(s.points, isNotEmpty);
      for (final p in s.points) {
        expect(p.dx, inInclusiveRange(-0.1, 1.1));
        expect(p.dy, inInclusiveRange(-0.1, 1.1));
      }
    }
  });

  test('chữ không có file → trả về rỗng, không ném lỗi', () async {
    expect(await KanaStrokeLoader.load('X'), isEmpty);
    expect(await KanaStrokeLoader.load(''), isEmpty);
  });
}

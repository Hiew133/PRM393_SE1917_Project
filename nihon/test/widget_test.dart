// Smoke test cơ bản cho app さくら.

import 'package:flutter_test/flutter_test.dart';

import 'package:nihon/app.dart';

void main() {
  testWidgets('Welcome screen hiển thị nút bắt đầu', (tester) async {
    await tester.pumpWidget(const SakuraApp());

    expect(find.text('Bắt đầu miễn phí'), findsOneWidget);
    expect(find.text('さくら'), findsOneWidget);
  });
}
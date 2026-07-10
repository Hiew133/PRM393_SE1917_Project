// Test LUỒNG THI NHẬT 2 (JPD123) trên UI thật: màn SpeakingScreen render đầy
// đủ (thẻ bài đọc 45đ → thẻ tranh câu ① → tiến độ → thẻ kết quả đúng cơ cấu
// 45/15×3/10) với đề lấy từ seed thật; chỉ AI + mic là bản giả.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nihon/features/speaking/models/nihon2_exam_sets.dart';
import 'package:nihon/features/speaking/speaking_controller.dart';
import 'package:nihon/features/speaking/speaking_screen.dart';

import 'speaking_fakes.dart';

void main() {
  testWidgets('Thi Nhật 2: đọc bài 45đ → 3 câu Q&A → kết quả /100',
      (tester) async {
    // Đề 1 từ seed thật (bài đọc + Q&A của đề demo chính thức JPD123).
    final exam = buildNihon2ExamSeeds().first;
    final scenario = exam.toScenario();
    final controller = SpeakingController(
      ai: FakeAi(), // chấm 80đ mỗi lượt
      speech: FakeSpeech(),
      initialScenario: scenario,
    );

    await tester.pumpWidget(MaterialApp(
      home: SpeakingScreen(
        examScenario: scenario,
        title: exam.title,
        controller: controller,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400)); // chờ lời chào giả

    // ── Giai đoạn ĐỌC BÀI: header Nhật 2 + thẻ bài đọc 45đ ghim trên cùng.
    expect(find.text('日本語２ thi nói · AI là giám khảo'), findsOneWidget);
    expect(find.text('BÀI ĐỌC · よんでください'), findsOneWidget);
    expect(find.text('45đ'), findsOneWidget);
    expect(find.textContaining('今年の８月'), findsOneWidget); // đoạn văn đề A-1
    expect(find.text('Đọc bài'), findsOneWidget); // chip tiến độ

    // ── SV đọc bài → sang câu ① THEO TRANH: thẻ tranh thay thẻ bài đọc.
    await controller.submitUserText(exam.passage);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Câu 1/3'), findsOneWidget);
    expect(find.text('TRANH · えを　みて　こたえてください'), findsOneWidget);
    expect(find.text('ハノイ → ホーチミン'), findsOneWidget); // caption tranh B-1
    expect(find.text('BÀI ĐỌC · よんでください'), findsNothing);

    // ── Câu ② ③ (không tranh): thẻ tranh biến mất.
    await controller.submitUserText('２じかんはんです。');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Câu 2/3'), findsOneWidget);
    expect(find.text('TRANH · えを　みて　こたえてください'), findsNothing);

    await controller.submitUserText('おかねが　ほしいです。');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Câu 3/3'), findsOneWidget);

    // ── Trả lời câu ③ → THI XONG: thẻ kết quả đúng cơ cấu JPD123.
    // Mỗi lượt 80đ → đọc 80×0.45=36/45, mỗi câu 80×0.15=12/15,
    // tác phong 80×0.10=8/10 → tổng 36+12×3+8 = 80/100.
    await controller.submitUserText('はるが　すきです。');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Hoàn thành'), findsOneWidget);
    expect(find.text('KẾT QUẢ (ước lượng)'), findsOneWidget);
    expect(find.text('80'), findsOneWidget); // tổng điểm
    expect(find.text('36/45'), findsOneWidget); // đọc bài
    expect(find.text('12/15'), findsNWidgets(3)); // 3 câu hỏi
    expect(find.text('8/10'), findsOneWidget); // tác phong
    expect(find.text('Đã hoàn thành phần thi.'), findsOneWidget);
  });
}

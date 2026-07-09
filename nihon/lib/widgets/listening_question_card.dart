import 'package:flutter/material.dart';
import 'listening_option.dart';

class ListeningQuestionCard extends StatefulWidget {
  const ListeningQuestionCard({super.key});

  @override
  State<ListeningQuestionCard> createState() =>
      _ListeningQuestionCardState();
}

class _ListeningQuestionCardState
    extends State<ListeningQuestionCard> {
  String? selectedAnswer;

  static const Color textGrey = Color(0xFF8C8175);
  static const Color textDark = Color(0xFF2D261F);
  static const Color primaryOrange = Color(0xFFE8953C);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "CÂU HỎI 1/3",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textGrey,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          "この会話の内容は何ですか。",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          "Nội dung chính của đoạn hội thoại là gì?",
          style: TextStyle(
            fontSize: 14,
            color: textGrey,
          ),
        ),

        const SizedBox(height: 20),

        ListeningOption(
          label: "A",
          text: "あいさつ",
          isSelected: selectedAnswer == "A",
          onTap: () {
            setState(() {
              selectedAnswer = "A";
            });
          },
        ),

        ListeningOption(
          label: "B",
          text: "買い物",
          isSelected: selectedAnswer == "B",
          onTap: () {
            setState(() {
              selectedAnswer = "B";
            });
          },
        ),

        ListeningOption(
          label: "C",
          text: "旅行",
          isSelected: selectedAnswer == "C",
          onTap: () {
            setState(() {
              selectedAnswer = "C";
            });
          },
        ),

        ListeningOption(
          label: "D",
          text: "仕事",
          isSelected: selectedAnswer == "D",
          onTap: () {
            setState(() {
              selectedAnswer = "D";
            });
          },
        ),

        if (selectedAnswer != null) ...[
          const SizedBox(height: 8),

          Center(
            child: Text(
              "Bạn đã chọn đáp án $selectedAnswer",
              style: const TextStyle(
                color: primaryOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
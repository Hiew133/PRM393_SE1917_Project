import 'package:flutter/material.dart';

/// Bảng màu của app さくら – trích trực tiếp từ file thiết kế.
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────
  static const Color brand = Color(0xFFF59E0B); // amber chủ đạo
  static const Color brandDark = Color(0xFFD97B0A);

  // ── Màu theo kỹ năng ──────────────────────────────────
  static const Color vocab = Color(0xFFE8543A); // 語彙 · Từ vựng
  static const Color kanji = Color(0xFF9B4FCC); // 漢字 · Kanji
  static const Color reading = Color(0xFF0EA5A0); // 読む · Đọc hiểu
  static const Color listening = Color(0xFFE88729); // 聴く · Nghe
  static const Color speaking = Color(0xFF3BAD6C); // 話す · Nói

  // ── Nền & bề mặt ──────────────────────────────────────
  static const Color background = Color(0xFFFFFBF2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFFF4E0);
  static const Color border = Color(0xFFF0E8D8);

  // ── Chữ ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D1F0E);
  static const Color textSecondary = Color(0xFF6B5342);
  static const Color textMuted = Color(0xFF8B7355);
  static const Color textFaint = Color(0xFFA8917A);

  // ── Cấp độ SRS ────────────────────────────────────────
  static const Color srsApprentice = Color(0xFFFF7F9E); // 見習い
  static const Color srsGuru = Color(0xFF9B4FCC); // 弟子
  static const Color srsMaster = Color(0xFF3880DB); // 達人
  static const Color srsEnlightened = Color(0xFF0EA5A0); // 悟り
  static const Color srsBurned = Color(0xFF7B7B7B); // 燃焼済

  // ── Gradient ──────────────────────────────────────────
  static const LinearGradient welcomeBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8EC), Color(0xFFFFE3B8), Color(0xFFFFCB94)],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient resumeCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1C0C), Color(0xFF452E18)],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF59E0B), Color(0xFFE88729)],
  );
}
import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Kiểu chữ dùng chung.
///
/// - [latin]  : DM Sans  – dùng cho tiếng Việt / latin.
/// - [jp]     : Noto Sans JP – dùng cho ký tự tiếng Nhật (kanji, kana).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle latin({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height ?? 1.3,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle jp({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: 'NotoSansJP',
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ── Một vài style hay dùng ────────────────────────────
  static TextStyle get screenTitle =>
      latin(size: 17, weight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get sectionLabel => latin(
        size: 14,
        weight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.02,
      );

  static TextStyle get overline => latin(
        size: 10,
        weight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.7,
      );
}
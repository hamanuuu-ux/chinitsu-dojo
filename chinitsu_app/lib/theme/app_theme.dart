import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HTML v2のCSS変数をそのまま移植したテーマ定義。
class AppColors {
  static const ink = Color(0xFF1A0F00);
  static const paper = Color(0xFFF7F1E3);
  static const paper2 = Color(0xFFEDE4CC);
  static const paper3 = Color(0xFFE4D8BE);
  static const red = Color(0xFFB5282A);
  static const gold = Color(0xFF9A7200);
  static const green = Color(0xFF1B5E30);
  static const greenLight = Color(0xFF2D8048);
  static const tileBorder = Color(0xFFD4C4A8);
  static const white = Color(0xFFFFFFFF);
  static const rpPlus = Color(0xFF4CAF50);
  static const rpMinus = Color(0xFFE74C3C);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
      ),
      textTheme: GoogleFonts.notoSerifTextTheme().apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
    );
  }

  /// タイトル用フォント（Shippori Mincho）
  static TextStyle titleStyle({double fontSize = 28, Color? color}) {
    return GoogleFonts.shipporiMincho(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color ?? AppColors.ink,
    );
  }

  /// 本文用フォント（Noto Serif JP）
  static TextStyle bodyStyle({double fontSize = 16, Color? color}) {
    return GoogleFonts.notoSerif(
      fontSize: fontSize,
      color: color ?? AppColors.ink,
    );
  }
}

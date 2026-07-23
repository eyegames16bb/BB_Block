import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const Color woodMid = Color(0xFF9C6B32);
  static const Color woodDeep = Color(0xFF6B4423);
  static const Color navy = Color(0xFF223140);
  static const Color gold = Color(0xFFA9791F);
  static const Color paper = Color(0xFFF5EFE2);
  static const Color ink = Color(0xFF2B1F14);
}

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: AppColors.woodMid,
      scaffoldBackgroundColor: AppColors.paper,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, AppColors.ink),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color onSurface) {
    final display = GoogleFonts.fredokaTextTheme(base);
    final body = GoogleFonts.nunitoTextTheme(base);

    return body.copyWith(
      displayLarge: display.displayLarge,
      displayMedium: display.displayMedium,
      displaySmall: display.displaySmall,
      headlineLarge: display.headlineLarge,
      headlineMedium: display.headlineMedium,
      headlineSmall: display.headlineSmall,
      titleLarge: display.titleLarge,
    );
  }
}

import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Roboto'; // Replace with chosen font later if needed

  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily, fontSize: 57, fontWeight: FontWeight.bold, letterSpacing: -0.25),
    displayMedium: TextStyle(fontFamily: _fontFamily, fontSize: 45, fontWeight: FontWeight.bold, letterSpacing: 0),
    displaySmall: TextStyle(fontFamily: _fontFamily, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 0),
    headlineLarge: TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 0),
    headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0),
    headlineSmall: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0),
    titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0),
    titleMedium: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
    titleSmall: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.normal, letterSpacing: 0.5),
    bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.normal, letterSpacing: 0.25),
    bodySmall: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.normal, letterSpacing: 0.4),
    labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    labelSmall: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );

  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily, fontSize: 57, fontWeight: FontWeight.bold, letterSpacing: -0.25),
    displayMedium: TextStyle(fontFamily: _fontFamily, fontSize: 45, fontWeight: FontWeight.bold, letterSpacing: 0),
    displaySmall: TextStyle(fontFamily: _fontFamily, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 0),
    headlineLarge: TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 0),
    headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0),
    headlineSmall: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0),
    titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0),
    titleMedium: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
    titleSmall: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.normal, letterSpacing: 0.5),
    bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.normal, letterSpacing: 0.25),
    bodySmall: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.normal, letterSpacing: 0.4),
    labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    labelSmall: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );
}

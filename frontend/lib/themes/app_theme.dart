import 'package:flutter/material.dart';

class AppTheme {
  // Main colors
  static const Color background = Color(0xFF0B0B0B);
  static const Color sidebar = Color(0xFF111111);
  static const Color surface = Color(0xFF171717);
  static const Color surfaceLight = Color(0xFF202020);

  static const Color border = Color(0xFF2A2A2A);

  static const Color primaryText = Color(0xFFF5F5F5);
  static const Color secondaryText = Color(0xFF9B9B9B);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    scaffoldBackgroundColor: background,

    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: primaryText,
    ),

    fontFamily: 'Arial',

    useMaterial3: true,
  );
}
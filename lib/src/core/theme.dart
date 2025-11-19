import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFA8D0E6);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF0F172A);

  static ThemeData lightTheme = _baseTheme(Brightness.light).copyWith(
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: primaryColor,
    ),
  );

  static ThemeData darkTheme = _baseTheme(Brightness.dark).copyWith(
    scaffoldBackgroundColor: const Color(0xFF0F1524),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F1524),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
    ),
  );

  static ThemeData _baseTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final bodyColor = isLight ? textColor : Colors.white;

    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          color: bodyColor,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isLight ? textColor : Colors.black87,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      cardTheme: CardThemeData(
        color: isLight ? Colors.white : const Color(0xFF1B2235),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}

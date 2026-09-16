import 'package:flutter/material.dart';

class AppTheme {
  // Mode Clair
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0284C7),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF64748B),
      outline: Color(0xFFE2E8F0),
    ),
  );

  // Mode Sombre
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B0F19),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF38BDF8),
      surface: Color(0xFF161F30),
      onSurface: Color(0xFFF8FAFC),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF22314E),
    ),
  );
}

abstract class AppStatusColors {
  static const online = Color(0xFF10B981); // Green
  static const offline = Color(0xFF64748B); // Slate
  static const wakingUp = Color(0xFFF59E0B); // Amber
}

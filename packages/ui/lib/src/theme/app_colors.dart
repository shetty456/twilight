import 'package:flutter/material.dart';

abstract final class AppColors {
  // Neutrals
  static const Color black = Color(0xFF0A0A0A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE5E5E5);
  static const Color grey400 = Color(0xFFA3A3A3);
  static const Color grey600 = Color(0xFF525252);
  static const Color grey800 = Color(0xFF262626);

  // Primary — override per product via ThemeData
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFFA5B4FC);
  static const Color primaryDark = Color(0xFF4338CA);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}

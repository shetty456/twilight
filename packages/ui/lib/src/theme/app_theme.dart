import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

/// Brand choices supplied by each app while sharing the same component theme.
class AppThemeConfig {
  const AppThemeConfig({
    this.primaryColor = AppColors.primary,
    this.fontFamily,
  });

  final Color primaryColor;
  final String? fontFamily;
}

abstract final class AppTheme {
  static ThemeData light(
          {Color? primaryColor,
          AppThemeConfig config = const AppThemeConfig()}) =>
      _build(Brightness.light, config, primaryColor);

  static ThemeData dark(
          {Color? primaryColor,
          AppThemeConfig config = const AppThemeConfig()}) =>
      _build(Brightness.dark, config, primaryColor);

  static ThemeData _build(
    Brightness brightness,
    AppThemeConfig config,
    Color? primaryColor,
  ) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor ?? config.primaryColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: config.fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headline1.copyWith(color: scheme.onSurface),
        displayMedium:
            AppTextStyles.headline2.copyWith(color: scheme.onSurface),
        titleLarge: AppTextStyles.title.copyWith(color: scheme.onSurface),
        bodyLarge: AppTextStyles.body.copyWith(color: scheme.onSurface),
        bodyMedium:
            AppTextStyles.bodySmall.copyWith(color: scheme.onSurfaceVariant),
        labelSmall:
            AppTextStyles.caption.copyWith(color: scheme.onSurfaceVariant),
        labelLarge: AppTextStyles.button.copyWith(color: scheme.onPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.title.copyWith(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}

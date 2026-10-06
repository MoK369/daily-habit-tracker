import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => _build(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    primaryText: AppColors.lightPrimaryText,
    secondaryText: AppColors.lightSecondaryText,
    border: AppColors.lightBorder,
    primary: AppColors.lightPrimary,
    primaryContainer: AppColors.lightPrimaryContainer,
    error: AppColors.lightError,
    errorContainer: AppColors.lightErrorContainer,
    appColors: AppThemeColors.light,
  );

  static ThemeData get darkTheme => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    primaryText: AppColors.darkPrimaryText,
    secondaryText: AppColors.darkSecondaryText,
    border: AppColors.darkBorder,
    primary: AppColors.darkPrimary,
    primaryContainer: AppColors.darkPrimaryContainer,
    error: AppColors.darkError,
    errorContainer: AppColors.darkErrorContainer,
    appColors: AppThemeColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color primaryText,
    required Color secondaryText,
    required Color border,
    required Color primary,
    required Color primaryContainer,
    required Color error,
    required Color errorContainer,
    required AppThemeColors appColors,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: primary,
      surface: background,
      onSurface: primaryText,
      onSurfaceVariant: secondaryText,
      outline: border,
      outlineVariant: border,
      error: error,
      errorContainer: errorContainer,
      onErrorContainer: error,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      extensions: [appColors],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: appColors.habitSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? appColors.success
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(background),
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide.none
              : BorderSide(color: border, width: 2),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryContainer,
        foregroundColor: primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: appColors.progressTrack,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(primary, 2),
        errorBorder: inputBorder(error),
        focusedErrorBorder: inputBorder(error, 2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

import 'package:claude_code/core/theme/app_colors.dart';
import 'package:claude_code/core/theme/app_theme.dart';
import 'package:claude_code/core/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses the Figma light palette', () {
      final theme = AppTheme.lightTheme;

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(theme.colorScheme.primary, AppColors.lightPrimary);
      expect(theme.colorScheme.onSurface, AppColors.lightPrimaryText);
      expect(theme.extension<AppThemeColors>(), AppThemeColors.light);
    });

    test('dark theme uses the Figma dark palette', () {
      final theme = AppTheme.darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(theme.colorScheme.primary, AppColors.darkPrimary);
      expect(theme.colorScheme.onSurface, AppColors.darkPrimaryText);
      expect(theme.extension<AppThemeColors>(), AppThemeColors.dark);
    });
  });
}

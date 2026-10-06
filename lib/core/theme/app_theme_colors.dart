import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens that have no matching [ColorScheme] role.
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.success,
    required this.successContainer,
    required this.habitSurface,
    required this.progressTrack,
  });

  /// Completion green: checked checkbox, streak text of a completed habit.
  final Color success;

  /// Background of a habit completed today.
  final Color successContainer;

  /// Background of a habit not completed today.
  final Color habitSurface;

  /// Unfilled part of the daily progress bar.
  final Color progressTrack;

  static const AppThemeColors light = AppThemeColors(
    success: AppColors.lightCompletion,
    successContainer: AppColors.lightCompletedSurface,
    habitSurface: AppColors.lightHabitSurface,
    progressTrack: AppColors.lightProgressTrack,
  );

  static const AppThemeColors dark = AppThemeColors(
    success: AppColors.darkCompletion,
    successContainer: AppColors.darkCompletedSurface,
    habitSurface: AppColors.darkHabitSurface,
    progressTrack: AppColors.darkProgressTrack,
  );

  @override
  AppThemeColors copyWith({
    Color? success,
    Color? successContainer,
    Color? habitSurface,
    Color? progressTrack,
  }) {
    return AppThemeColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      habitSurface: habitSurface ?? this.habitSurface,
      progressTrack: progressTrack ?? this.progressTrack,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      habitSurface: Color.lerp(habitSurface, other.habitSurface, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
    );
  }
}

extension AppThemeColorsX on BuildContext {
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>()!;
}

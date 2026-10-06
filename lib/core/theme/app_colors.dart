import 'package:flutter/material.dart';

/// Raw palette from the Figma "Color Palette" frame.
///
/// Widgets should read colors from `Theme.of(context).colorScheme` or
/// `context.appColors`, not from this class, so they follow the theme mode.
class AppColors {
  const AppColors._();

  // Light theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightPrimaryText = Color(0xFF1B1C20);
  static const Color lightSecondaryText = Color(0xFF60646C);
  static const Color lightHabitSurface = Color(0xFFF4F6FA);
  static const Color lightBorder = Color(0xFFD9DEE7);
  static const Color lightPrimary = Color(0xFF315DA8);
  static const Color lightPrimaryContainer = Color(0xFFEAF0FC);
  static const Color lightCompletion = Color(0xFF287547);
  static const Color lightCompletedSurface = Color(0xFFEDF7EF);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightErrorContainer = Color(0xFFFFF1F0);
  static const Color lightProgressTrack = Color(0xFFFFFFFF);

  // Dark theme
  static const Color darkBackground = Color(0xFF191C20);
  static const Color darkPrimaryText = Color(0xFFE5E8EE);
  static const Color darkSecondaryText = Color(0xFFADB4BF);
  static const Color darkHabitSurface = Color(0xFF242830);
  static const Color darkBorder = Color(0xFF454B55);
  static const Color darkPrimary = Color(0xFFADC6FF);
  static const Color darkPrimaryContainer = Color(0xFF284677);
  static const Color darkCompletion = Color(0xFF8ED4A7);
  static const Color darkCompletedSurface = Color(0xFF203A2B);
  static const Color darkError = Color(0xFFBA1A1A);
  static const Color darkErrorContainer = Color(0xFFFFF1F0);
  static const Color darkProgressTrack = Color(0xFF152C50);
}

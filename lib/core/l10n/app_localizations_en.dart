// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Daily Habit Tracker';

  @override
  String get habitNameRequired => 'Habit name is required.';

  @override
  String get storageFailureMessage => 'Something went wrong. Please try again.';

  @override
  String get duplicateHabitNameMessage =>
      'A habit with this name already exists.';

  @override
  String get unexpectedErrorMessage =>
      'Something unexpected happened. Please try again.';
}

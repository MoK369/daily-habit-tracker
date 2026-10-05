import '../../l10n/app_localizations.dart';
import '../app_failure.dart';

/// The single place [AppFailure] is turned into user-facing text — meant to
/// be called from presentation widgets/cubits only.
extension AppFailureLocalization on AppFailure {
  String localized(AppLocalizations l10n) => switch (this) {
    CacheFailure(:final message) => message ?? l10n.storageFailureMessage,
    ValidationFailure(:final message) => message ?? l10n.habitNameRequired,
    DuplicateNameFailure(:final message) =>
      message ?? l10n.duplicateHabitNameMessage,
    UnexpectedFailure(:final message) => message ?? l10n.unexpectedErrorMessage,
  };
}

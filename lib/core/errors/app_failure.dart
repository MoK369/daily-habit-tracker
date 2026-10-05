/// User-facing failure types. Data-layer/package exceptions (Hive, platform,
/// future remote APIs, ...) are mapped onto one of these via [ErrorHandler]
/// so the domain/presentation layers never see low-level exception details.
sealed class AppFailure {
  /// Passthrough text safe to show as-is, e.g. a message a remote API
  /// already returns in user-friendly form. Null means: use the centralized
  /// localized fallback for this failure type (see AppFailureLocalization).
  final String? message;

  /// Raw cause, for logs/debugging only — never shown to the user.
  final Object? details;

  const AppFailure({this.message, this.details});
}

class CacheFailure extends AppFailure {
  const CacheFailure({super.message, super.details});
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({super.message, super.details});
}

class DuplicateNameFailure extends AppFailure {
  const DuplicateNameFailure({super.message, super.details});
}

class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({super.message, super.details});
}

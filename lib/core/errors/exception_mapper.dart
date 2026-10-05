import 'app_failure.dart';

/// Strategy for mapping one category of raw exceptions (a specific package
/// or data source) onto [AppFailure]. Parameters are typed `Object`, not
/// `Exception`, because some libraries (e.g. Hive's `HiveError`) signal
/// recoverable, out-of-our-control conditions via `Error` rather than
/// `Exception` — this still needs to be classifiable here.
///
/// To support a new data source (e.g. a future remote API), add a new
/// implementation and register it; [ErrorHandler] and [safeCall] need no
/// changes.
abstract class ExceptionMapper {
  bool canHandle(Object exception);

  AppFailure map(Object exception, StackTrace stackTrace);
}

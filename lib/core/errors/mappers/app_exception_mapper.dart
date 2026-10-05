import 'package:injectable/injectable.dart';

import '../app_failure.dart';
import '../exception_mapper.dart';
import '../exceptions.dart';

/// Maps exceptions our own code throws deliberately (not tied to a specific
/// third-party package/data source) onto [AppFailure]. [CacheException] is
/// excluded here since [HiveExceptionMapper] already owns it.
@Injectable(as: ExceptionMapper)
class AppExceptionMapper implements ExceptionMapper {
  @override
  bool canHandle(Object exception) =>
      exception is AppException && exception is! CacheException;

  @override
  AppFailure map(Object exception, StackTrace stackTrace) {
    final e = exception as AppException;
    return switch (e) {
      DuplicateNameException() => DuplicateNameFailure(message: e.message),
      _ => UnexpectedFailure(message: e.message, details: e),
    };
  }
}

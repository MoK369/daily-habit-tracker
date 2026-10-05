import 'app_failure.dart';
import 'exception_mapper.dart';

class ErrorHandler {
  const ErrorHandler(this._mappers);

  final List<ExceptionMapper> _mappers;

  AppFailure handle(Object exception, [StackTrace? stackTrace]) {
    final trace = stackTrace ?? StackTrace.current;
    for (final mapper in _mappers) {
      if (mapper.canHandle(exception)) {
        return mapper.map(exception, trace);
      }
    }
    return UnexpectedFailure(details: exception);
  }
}

import 'package:injectable/injectable.dart';

import '../errors/error_handler.dart';
import '../errors/exception_mapper.dart';
import 'injection.dart';

/// `injectable` doesn't auto-resolve a `List<T>` constructor parameter from
/// multiple classes registered `as: T` — it only guarantees
/// `getIt.getAll<T>()` works. So [ErrorHandler] is built explicitly here,
/// gathering every registered [ExceptionMapper].
///
/// Must be `@lazySingleton`, not `@singleton`: `@singleton` registers
/// eagerly (calls this getter immediately during `init()`), which can run
/// before the `ExceptionMapper` factories are registered, yielding an empty
/// list. `@lazySingleton` defers until the first `getIt<ErrorHandler>()`
/// call, by which point `init()` has fully completed.
@module
abstract class ErrorHandlerModule {
  @lazySingleton
  ErrorHandler get errorHandler =>
      ErrorHandler(getIt.getAll<ExceptionMapper>().toList());
}

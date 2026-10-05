---
name: dart-error-handling-architecture
description: Sets up a scalable error-handling architecture for Dart and Flutter projects that follow Clean Architecture. It covers a safeCall wrapper for repository methods that turns sync and async exceptions into a BaseResponse (Success or Error), a pluggable ErrorHandler with one ExceptionMapper per data source (Hive, Dio/HTTP, platform channels, the app's own exceptions), a sealed AppFailure hierarchy with user-friendly names, and a UI-only mapper from AppFailure to localized text. Use this skill whenever the user wants error handling in a Dart or Flutter project, asks for a BaseResponse, Result, Either or Failure sealed class, a safeCall or ErrorHandler, wants to stop raw exceptions from leaking out of repositories into the UI, wants Hive, Dio or SocketException errors turned into user messages, or wants to reuse this architecture in another project. Use it even when the user doesn't name these classes.
model: claude-sonnet-5
---

# Dart Error Handling Architecture

Repositories are the only place that catches exceptions. Every repository method returns a `BaseResponse`, and its failure is always an `AppFailure`. The UI never sees a raw exception, and it turns a failure into text through one localizer. Supporting a new data source means adding one `ExceptionMapper`. Nothing else changes.

## Architecture at a glance

```
DataSource        throws a raw exception (HiveError, DioException, ...)
   |
Repository        with SafeCallMixin -> safeCall(() => datasource.call())
   |  catch (e, s)
ErrorHandler      asks each ExceptionMapper: canHandle? then map
   |
AppFailure        sealed class, wrapped as ErrorResponse(failure)
   |
Presentation      failure.localized(l10n)   <- the only place text is produced
```

## Workflow

Copy this checklist and track progress:

```
- [ ] 0. Survey the target project
- [ ] 1. Add BaseResponse
- [ ] 2. Add AppFailure
- [ ] 3. Add ExceptionMapper and ErrorHandler
- [ ] 4. Add SafeCallMixin
- [ ] 5. Write one ExceptionMapper per data source
- [ ] 6. Wire dependency injection
- [ ] 7. Add the presentation localizer and its strings
- [ ] 8. Verify
```

### 0. Survey the target project

- Check the Dart SDK in `pubspec.yaml`. Sealed classes and pattern matching need Dart 3.0 or later.
- Find the data sources: local databases (Hive, Isar, sqflite), HTTP clients (Dio, http), platform plugins.
- Check for existing `Failure`, `Exception` or `Result` types. Rename or reuse them rather than adding a second hierarchy beside them.
- Check the DI setup. The examples assume `get_it` with `injectable`. Without DI, pass the mappers to `ErrorHandler` by hand.
- Check whether the project has localization (`gen-l10n`, `intl`). The examples assume ARB files.

### 1. BaseResponse

```dart
import '../errors/app_failure.dart';

sealed class BaseResponse<T> {
  const BaseResponse();
}

final class SuccessResponse<T> extends BaseResponse<T> {
  const SuccessResponse(this.data);
  final T data;
}

final class ErrorResponse<T> extends BaseResponse<T> {
  const ErrorResponse(this.failure);
  final AppFailure failure;
}
```

Callers use an exhaustive `switch`, so the compiler reports any case they forget:

```dart
switch (response) {
  SuccessResponse(:final data) => emit(Loaded(data)),
  ErrorResponse(:final failure) => emit(Error(failure.localized(l10n))),
}
```

### 2. AppFailure

Name each failure for what the user experiences, not for the library that caused it. Write `CacheFailure`, not `HiveFailure`.

```dart
sealed class AppFailure {
  const AppFailure({this.message, this.details});

  /// Text that is safe to show as-is, such as a message the backend sends in user-friendly form.
  /// Null means the UI uses its localized fallback for this failure type.
  final String? message;

  /// The raw cause, for logs and debugging only. Never show it to the user.
  final Object? details;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({super.message, super.details});
}

class ServerFailure extends AppFailure {
  const ServerFailure({super.message, super.details});
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
```

Add a subclass only when the UI needs to react differently. Otherwise reuse an existing one.

### 3. ExceptionMapper and ErrorHandler

```dart
abstract class ExceptionMapper {
  /// Typed as Object, not Exception. Some libraries throw Error subtypes
  /// for conditions outside the app's control (see Rule 2 below).
  bool canHandle(Object exception);

  AppFailure map(Object exception, StackTrace stackTrace);
}
```

```dart
class ErrorHandler {
  const ErrorHandler(this._mappers);

  final List<ExceptionMapper> _mappers;

  AppFailure handle(Object exception, [StackTrace? stackTrace]) {
    final trace = stackTrace ?? StackTrace.current;
    for (final mapper in _mappers) {
      if (mapper.canHandle(exception)) return mapper.map(exception, trace);
    }
    return UnexpectedFailure(details: exception);
  }
}
```

The first mapper whose `canHandle` returns true wins. Make the `canHandle` checks mutually exclusive, so the order of registration never matters.

### 4. SafeCallMixin

```dart
import 'dart:async';

import 'base_response.dart';
import '../errors/error_handler.dart';

mixin SafeCallMixin {
  ErrorHandler get errorHandler;

  Future<BaseResponse<T>> safeCall<T>(FutureOr<T> Function() action) async {
    try {
      return SuccessResponse<T>(await action());
    } catch (e, s) {
      // Top-level boundary: catches everything only to report it as a failure.
      return ErrorResponse<T>(errorHandler.handle(e, s));
    }
  }
}
```

`FutureOr` lets one helper wrap both synchronous and asynchronous calls.

A repository uses the mixin like this:

```dart
class ItemRepositoryImpl with SafeCallMixin implements ItemRepository {
  ItemRepositoryImpl(this._local, this.errorHandler);

  final ItemLocalDataSource _local;

  @override
  final ErrorHandler errorHandler;

  @override
  Future<BaseResponse<List<Item>>> getItems() => safeCall(() => _local.getItems());

  @override
  Future<BaseResponse<void>> deleteItem(String id) =>
      safeCall(() => _local.deleteItem(id));
}
```

### 5. One ExceptionMapper per data source

**Local database (Hive CE).** `HiveError` extends `Error`, not `Exception`. Hive uses it for conditions the app can't control, such as a corrupted box, an unopened box or a missing adapter. `FileSystemException` can also come from Hive's file access.

```dart
import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: ExceptionMapper)
class HiveExceptionMapper implements ExceptionMapper {
  @override
  bool canHandle(Object exception) =>
      exception is HiveError || exception is FileSystemException;

  @override
  AppFailure map(Object exception, StackTrace stackTrace) =>
      // Hive's messages are internal, so they stay out of `message`.
      CacheFailure(details: exception);
}
```

**HTTP (Dio).** Pass a backend message through only when the backend is known to send user-safe text.

```dart
@Injectable(as: ExceptionMapper)
class DioExceptionMapper implements ExceptionMapper {
  @override
  bool canHandle(Object exception) => exception is DioException;

  @override
  AppFailure map(Object exception, StackTrace stackTrace) {
    final e = exception as DioException;
    final response = e.response;
    if (response == null) return NetworkFailure(details: e);

    final data = response.data;
    final backendMessage = data is Map<String, dynamic> ? data['message'] : null;
    return ServerFailure(
      message: backendMessage is String ? backendMessage : null,
      details: e,
    );
  }
}
```

**The app's own exceptions.** Define a base type and map it once.

```dart
abstract class AppException implements Exception {
  const AppException([this.message]);
  final String? message;
}

class DuplicateNameException extends AppException {
  const DuplicateNameException([super.message]);
}

@Injectable(as: ExceptionMapper)
class AppExceptionMapper implements ExceptionMapper {
  @override
  bool canHandle(Object exception) => exception is AppException;

  @override
  AppFailure map(Object exception, StackTrace stackTrace) => switch (exception) {
    DuplicateNameException(:final message) => DuplicateNameFailure(message: message),
    _ => UnexpectedFailure(details: exception),
  };
}
```

If a class such as `CacheException` should go to a different mapper, exclude it in this `canHandle`, for example with `exception is AppException && exception is! CacheException`.

### 6. Wire dependency injection

With `get_it` and `injectable`:

```dart
@InjectableInit(allowMultipleRegistrations: true)
FutureOr<GetIt> configureDependencies() async => getIt.init();
```

```dart
@module
abstract class ErrorHandlerModule {
  // lazySingleton, not singleton. singleton runs its getter during init(),
  // before the ExceptionMapper factories are registered, so the list comes back empty.
  @lazySingleton
  ErrorHandler get errorHandler =>
      ErrorHandler(getIt.getAll<ExceptionMapper>().toList());
}
```

`injectable` does not turn a `List<ExceptionMapper>` constructor parameter into all registered implementations. The module above collects them explicitly. `getAll` returns an `Iterable`, so call `.toList()`.

### 7. Presentation localizer (UI only)

Keep this file in a `presentation` folder so it's clear that only the UI layer imports it.

```dart
// lib/core/errors/presentation/app_failure_localizer.dart
import '../../l10n/app_localizations.dart';
import '../app_failure.dart';

extension AppFailureLocalization on AppFailure {
  String localized(AppLocalizations l10n) => switch (this) {
    NetworkFailure(:final message) => message ?? l10n.networkErrorMessage,
    ServerFailure(:final message) => message ?? l10n.serverErrorMessage,
    CacheFailure(:final message) => message ?? l10n.storageFailureMessage,
    ValidationFailure(:final message) => message ?? l10n.validationErrorMessage,
    DuplicateNameFailure(:final message) => message ?? l10n.duplicateNameMessage,
    UnexpectedFailure(:final message) => message ?? l10n.unexpectedErrorMessage,
  };
}
```

Each failure type needs an ARB key. The compiler rejects the switch if a new failure class has no case, which is the point of making it exhaustive.

## Rules

1. **Catch in one place.** Only `safeCall` and the mappers handle exceptions. Data sources and cubits don't add their own try/catch, except for the narrow recovery case in Rule 2.
2. **Errors and exceptions.** Dart uses `Error` for bugs, and `Exception` for conditions the app can recover from. Some libraries break this convention. Hive is one. The rules for handling them:
   - Never catch an `Error` to hide a bug. Use the `avoid_catching_errors` lint to enforce this.
   - Catch a library's `Error` type narrowly, only where the app can recover, and rethrow everything else.
   - Check with a type test in a mapper (`exception is HiveError`), not with an `on HiveError` catch clause. Only `safeCall` catches broadly, because it reports instead of recovering.
3. **`details` is for logs.** Log it, but never display it.
4. **`message` is for text that is already user-safe.** Use a backend's message or a deliberate app string. Don't pass a library's internal message through.
5. **Mappers should be mutually exclusive.** Two mappers that both accept the same exception make the result depend on registration order.
6. **Keep the layers separate.** The domain layer depends only on `AppFailure` and `BaseResponse`. Flutter and `AppLocalizations` belong in `presentation`.

## Verify

1. Run `dart run build_runner build` to regenerate the DI config. Older builds accepted `--delete-conflicting-outputs`, but recent ones ignore it.
2. Run `flutter gen-l10n` (or the Dart equivalent) after changing ARB files.
3. Run `flutter analyze` (or `dart analyze`). It must report no issues.
4. Check the mapping with a throwaway test. Put the file in `test/`, not outside the project, because package imports only resolve inside the project. Delete it afterwards. Cover:
   - A `HiveError` maps to `CacheFailure` with a null `message`.
   - A `DuplicateNameException('x')` maps to `DuplicateNameFailure` with `message == 'x'`.
   - An unknown error maps to `UnexpectedFailure`.
   - `ErrorHandler` built with the real mappers returns the correct failure, which confirms the DI list isn't empty.

## Final report

Tell the user:
- Which files were created or renamed.
- Which data sources got a mapper, and which ones still throw unmapped exceptions.
- Any ARB keys added, so they can review the wording.
- Anything that needs a decision, such as a backend message format that isn't user-safe.

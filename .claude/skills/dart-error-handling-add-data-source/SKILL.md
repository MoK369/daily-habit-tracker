---
name: dart-error-handling-add-data-source
description: Extends an existing Dart or Flutter error-handling architecture (BaseResponse, safeCall, ErrorHandler, ExceptionMapper, AppFailure) when a new data source appears, such as a remote API, SharedPreferences, SQLite, a platform plugin, or a second local store, or when a library upgrade adds new exception types. It covers wiring the source into repositories, writing its mapper, deciding whether to reuse or add a failure type, updating the localizer and ARB strings, and orchestrating cache, remote and fallback reads. Use this skill whenever the user says they are adding an API, a backend, a new database, offline support, caching, sync, a new plugin, or a new storage to a project that already uses safeCall, BaseResponse, ExceptionMapper or AppFailure. Also use it when they ask how to map new errors, add a new failure type, or handle an exception that is not mapped yet, even if they don't name the architecture.
model: claude-sonnet-5
---

# Adding a Data Source to the Error Handling Architecture

The architecture is built so that a new data source touches a fixed set of places. The data source itself does not get try/catch, and the UI does not change unless a new failure type is added. Follow the steps in order, and stop to check the design whenever a step seems to require editing the repository's error handling or the UI.

## Decision: new source, or an existing one?

Start by answering two questions:

1. **Does the source throw exceptions that are already mapped?** For example, a second Hive box throws `HiveError`, which is already handled. Then no mapper is needed, and the source only needs a datasource and repository wiring.
2. **Does the UI need to react differently to its failures?** If the user would see the same message as for an existing failure, reuse that failure. Add a new `AppFailure` subclass only when the UI needs to handle the case differently or show different text.

| Situation | Action |
|---|---|
| Same library, same kinds of failure | Datasource + repository only |
| New library, failures the UI can already express | Add one `ExceptionMapper` |
| New library, a failure the UI must treat differently | Add a subclass, a mapper, an ARB key and a localizer case |
| Library upgrade adds an exception type | Extend that library's `canHandle` |

## Workflow

```
- [ ] 0. Survey the new source and its exceptions
- [ ] 1. Add the datasource (no try/catch)
- [ ] 2. Decide reuse or new failure type
- [ ] 3. Write or extend the mapper
- [ ] 4. Wire the repository (orchestrate sources)
- [ ] 5. Register with DI
- [ ] 6. Update the localizer and ARB (only if a new failure type)
- [ ] 7. Verify
```

### 0. Survey the new source

Find out which exceptions it can throw. Read the package source or its docs, and don't guess. Dart libraries often mix `Exception` and `Error` (Hive uses `HiveError extends Error`), and HTTP clients wrap low-level socket errors in their own types. Note each exception type and what the user can do about it. A timeout, a missing permission and a corrupted file need different messages.

### 1. Add the datasource

Datasources let exceptions propagate. They never catch them, because the repository's `safeCall` is the only boundary.

```dart
abstract class WeatherRemoteDataSource {
  Future<List<Forecast>> fetchForecasts(String city);
}

@LazySingleton(as: WeatherRemoteDataSource)
class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  WeatherRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Forecast>> fetchForecasts(String city) async {
    final response = await _dio.get<List<dynamic>>('/forecasts', queryParameters: {'city': city});
    return response.data!.map((e) => Forecast.fromJson(e as Map<String, dynamic>)).toList();
  }
}
```

A `response.data!` that might be null is a parsing bug, not a network failure. Let it throw. The mapper will send it to `UnexpectedFailure`, and the logs will show the cause.

### 2. Reuse or add a failure type

Reuse first. Use the existing types from the first skill (`NetworkFailure`, `ServerFailure`, `CacheFailure`, `ValidationFailure`, `DuplicateNameFailure`, `UnexpectedFailure`). A new subclass is justified only when all of these hold:

- The UI has to do something different, such as offer a retry, open settings or show a login prompt.
- The text is different from every existing failure's text.
- The condition will happen in real use, not only in a rare bug.

Example of adding one: a permission denial needs to open settings, which a generic failure can't express.

```dart
class PermissionFailure extends AppFailure {
  const PermissionFailure({super.message, super.details});
}
```

### 3. Write or extend the mapper

One mapper per library, grouped in a folder per source. Keep `canHandle` exclusive with other mappers.

```dart
// lib/core/errors/mappers/remote/dio_exception_mapper.dart
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

A library that throws in more than one shape gets its own branches in `map`, not separate mappers.

```dart
@override
AppFailure map(Object exception, StackTrace stackTrace) {
  final e = exception as DioException;
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.connectionError => NetworkFailure(details: e),
    DioExceptionType.badResponse => ServerFailure(
        message: _userSafeMessage(e.response?.data),
        details: e,
      ),
    _ => UnexpectedFailure(details: e),
  };
}
```

Platform plugins usually throw `PlatformException`. Map it to the failure the UI should show, not to the code the plugin sends:

```dart
@Injectable(as: ExceptionMapper)
class PlatformExceptionMapper implements ExceptionMapper {
  @override
  bool canHandle(Object exception) => exception is PlatformException;

  @override
  AppFailure map(Object exception, StackTrace stackTrace) =>
      CacheFailure(details: exception);
}
```

**Overlap.** If two sources can throw the same type, `canHandle` alone won't resolve it. Two cases:

- Both mappers map to the same failure. Keep the overlap and note it in a comment.
- The types need different failures. Narrow the type test, for example by checking the operation that failed, or move the decision into the repository, which knows which source it called.

### 4. Wire the repository

The repository decides how sources combine. It is the orchestration layer, so business policy such as cache-first, network-first or offline fallback lives there and nowhere else.

```dart
class WeatherRepositoryImpl with SafeCallMixin implements WeatherRepository {
  WeatherRepositoryImpl(this._remote, this._local, this.errorHandler);

  final WeatherRemoteDataSource _remote;
  final WeatherLocalDataSource _local;

  @override
  final ErrorHandler errorHandler;

  @override
  Future<BaseResponse<List<Forecast>>> getForecasts(String city) async {
    final remote = await safeCall(() => _remote.fetchForecasts(city));
    if (remote case SuccessResponse(:final data)) {
      // A cache write failure shouldn't hide fresh data from the user.
      await safeCall(() => _local.saveForecasts(city, data));
      return SuccessResponse(data);
    }
    // Offline or server down: serve what we have.
    return safeCall(() => _local.getForecasts(city));
  }
}
```

The write result is ignored on purpose. The product decides whether a cache failure is visible, so decide it here and leave a comment saying why. If the cache is required, return its failure instead.

When the orchestration needs to change the type of a response, add a small mapping helper to `BaseResponse`, so the code doesn't rebuild the switch every time:

```dart
extension BaseResponseMap<T> on BaseResponse<T> {
  BaseResponse<R> map<R>(R Function(T data) transform) => switch (this) {
    SuccessResponse(:final data) => SuccessResponse(transform(data)),
    ErrorResponse(:final failure) => ErrorResponse(failure),
  };
}
```

### 5. Register with DI

The datasource and mapper use `@LazySingleton(as: ...)` or `@Injectable(as: ...)`. Run the generator, and the mapper is added to `getIt.getAll<ExceptionMapper>()` with no further changes. The `ErrorHandler` module doesn't change, because it already gathers every mapper.

```bash
dart run build_runner build
```

If a mapper is missing from the generated config, check that `allowMultipleRegistrations: true` is still set in `@InjectableInit`, and that the mapper uses `as: ExceptionMapper`.

### 6. Update the localizer and ARB (only for a new failure type)

Adding a subclass to a sealed class makes the localizer's `switch` incomplete, and the analyzer reports it. Use that as the checklist.

```dart
PermissionFailure(:final message) => message ?? l10n.permissionDeniedMessage,
```

```json
"permissionDeniedMessage": "Allow access in Settings to continue.",
"@permissionDeniedMessage": { "description": "Shown when a permission is denied" }
```

Then regenerate: `flutter gen-l10n`. Don't hand-edit the generated `app_localizations*.dart` files.

### 7. Verify

- `dart run build_runner build` completes with no errors.
- `flutter analyze` reports no issues. An incomplete `switch` on `AppFailure` means a failure type has no localized text yet.
- Write a throwaway test in `test/` (not outside the project, or package imports won't resolve) and delete it afterwards. Check:
  - The new library's exception maps to the expected failure.
  - The orchestration returns the remote data when it succeeds.
  - It falls back to the cache when the remote fails.
  - `ErrorHandler` contains the new mapper. An empty list means the DI module changed in a way that breaks the lazy singleton.

## Rules

1. **No try/catch in datasources.** The repository's `safeCall` is the only boundary, so behavior stays in one place.
2. **Failure types are about the UI.** Name them for what the user can do, not for the library. `NetworkFailure` is fine, `DioFailure` is not.
3. **Mappers are exclusive.** When two mappers could match the same exception, make one narrower or move the decision into the repository.
4. **Orchestration is in the repository.** Caching, fallback and retry policy belong there. Datasources only do I/O, and mappers only translate exceptions.
5. **Pass backend messages through only when they are user-safe.** Anything else goes in `details`, which is for logs only.
6. **Don't reuse `details` as UI text.** It's for debugging.
7. **Reuse before adding.** A new failure type costs a subclass, a mapper case, an ARB key and a localizer case. Make sure the UI really needs it.
8. **A library upgrade is a mapper change.** Extend `canHandle` and `map`, and leave the repository and UI alone unless the failure type changes.

## Common mistakes

- Catching the exception in the datasource, so the repository never sees it and the mapper never runs.
- Adding `DioFailure` or `HiveFailure`, which leak library names into the UI layer.
- Writing a repository that returns raw data for one method and `BaseResponse` for another. Every public repository method returns `BaseResponse`.
- Calling a datasource outside `safeCall`, which lets an exception escape the architecture.
- Editing `injection.config.dart` by hand. Regenerate it instead.
- Forgetting `flutter gen-l10n` after adding an ARB key, then wondering why `l10n.permissionDeniedMessage` doesn't exist.

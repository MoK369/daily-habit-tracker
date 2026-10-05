---
name: dart-safecall-repository-usage
description: Shows how to write repository methods with safeCall in a Dart or Flutter project that uses BaseResponse and AppFailure, and when safeCall should not be used. Use this skill whenever the user writes or reviews a repository method, asks how to wrap a call with safeCall, asks how to return a nullable value on failure instead of an ErrorResponse (safeCallOrNull), works with nullable results, streams, sync getters, void cleanup methods, retries, nested calls, or multi-step writes in a repository, or hits a type mismatch on BaseResponse. Use it even when the user only mentions a repository and doesn't name safeCall.
model: claude-sonnet-5
---

# Using safeCall in Repositories

`safeCall` is the default way to write a repository method. Most methods should use it, and it covers reads, writes, sync calls and async calls. It doesn't fit every case, though. A few cases need a different shape, and forcing them through `safeCall` produces wrong types or hidden bugs. This skill covers both the normal pattern and those exceptions.

## Default pattern

Wrap the whole call that touches a data source in one `safeCall`. Return the result unchanged.

```dart
class HabitRepositoryImpl with SafeCallMixin implements HabitRepository {
  HabitRepositoryImpl(this._local, this.errorHandler);

  final HabitLocalDataSource _local;

  @override
  final ErrorHandler errorHandler;

  @override
  Future<BaseResponse<List<Habit>>> getHabits() => safeCall(() => _local.getHabits());

  @override
  Future<BaseResponse<void>> deleteHabit(String id) => safeCall(() => _local.deleteHabit(id));
}
```

Some rules that apply to every method:

- **One `safeCall` per repository method for each independent operation.** Don't put a `safeCall` around every line of a method. Put it around the logical operation.
- **Keep business logic outside the wrapped block when it can't fail.** Validation that returns a `ValidationFailure` should return early, before calling the data source.
- **Return the `BaseResponse`.** Don't unwrap it inside the repository. The caller decides what to do with a failure.

Validation before a write is a normal early return:

```dart
@override
Future<BaseResponse<Habit>> addHabit(String name) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return ErrorResponse(const ValidationFailure());
  }
  return safeCall(() async {
    final exists = await _local.existsByName(trimmed);
    if (exists) throw const DuplicateNameException();
    return _local.insertHabit(trimmed);
  });
}
```

Throwing `DuplicateNameException` inside `safeCall` is intentional. The mapper turns it into `DuplicateNameFailure`, so the rule stays in one place. Returning `ErrorResponse` directly is fine for a check that doesn't involve a data source, like the empty name above.

## When `safeCall` can't be used

Check for these cases before wrapping a method. Each one needs a different shape.

### 1. The method must return a nullable data type on failure

Some methods must return `Future<T?>` directly, with no `BaseResponse`. This happens when an external interface or callback type fixes the signature, or when a UI-only fallback is acceptable. Use `safeCallOrNull`. It returns the value on success and `null` on failure. The failure still goes through `ErrorHandler`, so it's logged in one place before it's discarded.

```dart
mixin SafeCallMixin {
  // ...safeCall as before...

  Future<T?> safeCallOrNull<T>(FutureOr<T> Function() action) async {
    try {
      return await action();
    } catch (e, s) {
      debugPrint('Dropped failure: ${errorHandler.handle(e, s).details}');
      return null;
    }
  }
}
```

```dart
@override
Future<String?> loadAvatarUrl() => safeCallOrNull(() => _remote.fetchAvatarUrl());
```

This discards the failure, so the caller can't tell "no avatar" from "request failed". Use it only where that difference doesn't matter to the user. When the UI needs to show an error, return `BaseResponse` instead.

"Not found" is different from failure, so keep it in `BaseResponse`. A nullable data type inside a successful response represents it:

```dart
@override
Future<BaseResponse<Habit?>> findHabit(String id) =>
    safeCall<Habit?>(() => _local.findHabit(id));
```

### 2. Streams

`safeCall` returns one `Future`. A stream keeps emitting, so it needs its own wrapper. Do the mapping inside an `async*` generator, so each error becomes an `ErrorResponse` event:

```dart
@override
Stream<BaseResponse<List<Habit>>> watchHabits() async* {
  try {
    await for (final habits in _local.watchHabits()) {
      yield SuccessResponse(habits);
    }
  } catch (e, s) {
    yield ErrorResponse(errorHandler.handle(e, s));
  }
}
```

The stream ends after an error. If the UI should keep listening, restart the source inside a loop, and make sure the restart is bounded so it can't spin on a permanent error.

`stream.handleError(...)` isn't a fit. Its callback can't emit a value, so the subscriber gets an error event rather than an `ErrorResponse`.

### 3. Synchronous, non-Future methods

`safeCall` takes a `FutureOr` function and always returns a `Future`. A synchronous getter that returns a plain value doesn't belong in a repository. Either make it a `Future`, or move it into the datasource or a use case. If it can throw and the repository has to expose it, wrap it with a small local helper that returns `BaseResponse<T>` synchronously:

```dart
BaseResponse<T> runSync<T>(T Function() action) {
  try {
    return SuccessResponse(action());
  } catch (e, s) {
    return ErrorResponse(errorHandler.handle(e, s));
  }
}
```

Use this sparingly. If the method is needed in many places, consider making it async, which keeps one code path.

### 4. Cleanup and `void`-returning lifecycle methods

Methods such as `close()` or `dispose()` have no caller who can act on a failure. Keep them outside `safeCall`, but still catch what they throw, and log it. A wrapper that only logs is clearer than an unhandled crash during shutdown:

```dart
@override
Future<void> close() async {
  final response = await safeCall(() => _local.close());
  if (response case ErrorResponse(:final failure)) {
    debugPrint('Local store failed to close: ${failure.details}');
  }
}
```

Don't call `safeCall` and ignore its result silently. Either handle the response or document why it's ignored.

### 5. Retries

Put the retry loop inside the action, so each attempt is a separate call and the final failure is the one that gets mapped. Putting the whole loop around `safeCall` would retry a failure the wrapper has already converted:

```dart
@override
Future<BaseResponse<Forecast>> fetchWithRetry(String city) => safeCall(() async {
  for (var attempt = 1; ; attempt++) {
    try {
      return await _remote.fetchForecast(city);
    } on DioException catch (e) {
      if (attempt >= 3 || e.type != DioExceptionType.connectionTimeout) rethrow;
      await Future<void>.delayed(Duration(seconds: attempt));
    }
  }
});
```

The `on DioException` clause is the narrow catch the rule allows: it retries only the timeout, and every other failure goes through `safeCall` unchanged.

### 6. Multi-step writes

Put a sequence that must succeed or fail together inside one `safeCall`, and use the data source's transaction if it has one. Separate `safeCall`s would leave partial writes behind when the second step fails.

```dart
@override
Future<BaseResponse<void>> renameHabit(String id, String newName) => safeCall(() async {
  await _local.transaction(() async {
    await _local.updateName(id, newName);
    await _local.appendAudit('rename', id);
  });
});
```

## Mistakes to avoid

**Nested `safeCall`.** An inner `safeCall` returns an `ErrorResponse` instead of throwing, so the outer call sees a successful value that happens to be a response. Call the data source directly inside one `safeCall`, or compose responses explicitly:

```dart
// Wrong: outer succeeds with an ErrorResponse inside it
return safeCall(() => safeCall(() => _local.getHabits()));

// Right
return safeCall(() => _local.getHabits());
```

**Wrapping the data source's own `try`.** If a datasource already catches and rethrows as a different type, the mapper sees the wrong exception. Let exceptions propagate from the datasource, unless the catch is the narrow recovery case described in the architecture's rules.

**Using `safeCallOrNull` where the UI should show an error.** Returning `null` hides the failure. Use it only where that has no visible effect.

**Returning `BaseResponse<T>?`.** A nullable response is a third state that every caller must check. Use `BaseResponse<T?>` for "not found" and keep the response itself non-null.

## Verify

- Every public repository method returns `BaseResponse` or a `Stream` of them, unless it's in a documented exception case above.
- `flutter analyze` reports no issues. The sealed `switch` in callers will catch unhandled responses.
- For a method with a nullable failure path, a test (in `test/`, deleted afterwards if throwaway) checks that a `DuplicateNameException` or a `HiveError` reaches the caller as the expected failure, not as `null` or a crash.

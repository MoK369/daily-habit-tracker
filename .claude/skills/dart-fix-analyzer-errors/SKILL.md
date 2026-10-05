---
name: dart-fix-analyzer-errors
description: Finds and fixes Dart and Flutter static analysis errors (analyzer errors, warnings, lints, red squiggles, "doesn't compile") using flutter/dart analyze, dart fix, and build_runner, then verifies with tests. Use this skill whenever a Dart or Flutter project has compile or analyzer errors, after upgrading packages or the SDK, after a refactor or merge that broke the build, or when asked to "clean up", "fix the errors", or "make analyze pass", even if the user doesn't say "static analysis".
model: claude-sonnet-5-5
---

# Fixing Dart & Flutter Analyzer Errors

The goal is a clean `analyze` run with **behavior unchanged**. An error made to disappear without being fixed is worse than an error that stays visible, because it becomes a hidden runtime crash.

## Contents
- [Workflow](#workflow)
- [Fix Guidelines](#fix-guidelines)
  - [Null Safety](#null-safety)
  - [Types & Generics](#types--generics)
  - [Method Overrides](#method-overrides)
  - [Error Handling in catch blocks](#error-handling-in-catch-blocks)
- [Guardrails](#guardrails)
  - [When suppression is allowed](#when-suppression-is-allowed)
- [Final Report](#final-report)
- [Examples](#examples)

---

## Workflow

Copy this checklist and track progress:

```
- [ ] 0. Detect project type & make it safe to change
- [ ] 1. Restore dependencies and generated code
- [ ] 2. Run the analyzer
- [ ] 3. Apply automated fixes (and review them)
- [ ] 4. Fix remaining errors manually
- [ ] 5. Format the changed files
- [ ] 6. Verify (max 3 rounds)
- [ ] 7. Write the final report
```

### 0. Detect project type and make it safe to change

- If `pubspec.yaml` contains a `flutter:` SDK dependency, this is a **Flutter** project: use `flutter analyze` and `flutter test`. Otherwise use `dart analyze` and `dart test`. (`dart test` cannot run Flutter widget tests.)
- Check that the git working tree is clean (`git status`). If there are uncommitted changes, ask the user before continuing. Automated fixes touch many files, and a clean starting point makes every change easy to review or revert.
- Note the Dart SDK version (`dart --version`). Some fixes depend on it, such as wildcard `_` variables (Dart 3.7+) and patterns (Dart 3.0+).
- Check that `analysis_options.yaml` exists at the package root and `include:`s a standard rule set: `package:flutter_lints/flutter.yaml` for Flutter, `package:lints/recommended.yaml` for pure Dart. If it's missing or has no `include:`, don't create or change it yourself. Mention it in the report, because a config change changes what "clean" means for the whole team.
- If the Dart MCP server is connected, prefer its tools (`analyze_files`, `dart_fix`, `dart_format`) over the CLI commands below. They do the same job and return structured results. Otherwise use the CLI.

### 1. Restore dependencies and generated code

Many errors are not code bugs. They come from a missing package or stale generated files, so rule those out first.

```bash
flutter pub get        # or: dart pub get
```

If `pubspec.yaml` lists `build_runner` (common with freezed, json_serializable, injectable, retrofit, drift, mockito):

```bash
dart run build_runner build --delete-conflicting-outputs
```

Errors like "Undefined class `_$User`", "Target of URI hasn't been generated", or a missing `part '*.g.dart'` / `*.freezed.dart` mean **regenerate**, not rewrite. **Never edit generated files** (`*.g.dart`, `*.freezed.dart`, `*.config.dart`, `*.mocks.dart`). Fix the source file and regenerate.

### 2. Run the analyzer

```bash
flutter analyze        # or: dart analyze
```

Use the same command and flags in every round, so the finish line doesn't move. Save the error count from this first run for the final report.

### 3. Apply automated fixes and review them

```bash
dart fix --dry-run     # preview what will change
dart fix --apply
git diff --stat        # confirm the scope looks reasonable
```

Read the dry-run output before applying: the fixes should match the project's architecture, not just silence warnings. If `dart fix` changes files that have nothing to do with the reported errors, or touches public APIs in surprising ways, mention it in the report.

### 4. Fix remaining errors manually

Work through the remaining errors by file, using [Fix Guidelines](#fix-guidelines) below. Before each fix, read the surrounding code to understand **why** the error exists. The analyzer usually points at a real design question.

If the correct fix would change runtime behavior (different values, different control flow, a changed public API), **stop and ask the user** instead of choosing for them.

### 5. Format the changed files

Format only the Dart files you changed, so the diff stays focused on your fixes:

```bash
git diff --name-only --diff-filter=d -- '*.dart' | grep -vE '\.(g|freezed|config|mocks)\.dart$' | xargs -r dart format
```

Don't run `dart format .` on the whole project unless the user asks. It can reformat hundreds of untouched files and bury the real fixes in the diff. Formatting follows the project's `formatter:` settings (`page_width`, `trailing_commas`) in `analysis_options.yaml` if present.

### 6. Verify (max 3 rounds)

```bash
flutter analyze
flutter test           # or: dart test
```

- If analyze still reports errors, return to step 4.
- If tests fail with `TypeError` or `LateInitializationError`, a recent fix introduced a bad cast (`as T`) or an unsafe `late`. Revisit those specific changes.
- If tests failed **before** your changes too, say so in the report rather than trying to fix unrelated failures.

**Stop after 3 rounds** of analyze → fix → analyze. If errors remain, don't keep looping. Go to the final report and explain what is left and why.

### 7. Write the final report

See [Final Report](#final-report).

---

## Fix Guidelines

### Null Safety

When a value might be null, choose fixes **in this order**:

1. **Initialize it.** Use a constructor parameter, an initializer list, or a sensible default value. This is the safest fix because the problem can't come back.
2. **Make it nullable and handle null.** Use `Type?`, then `?.`, `??`, or an explicit check.
3. **Use `late` only when initialization is guaranteed** before first read. Typical cases are `initState()` in a `State`, dependency-injection setup, or a test's `setUp()`. If you can't point to the exact line that guarantees it, don't use `late`.

Why the order matters: `late` and `!` do not fix a null problem. They move it from compile time (safe, visible) to runtime (a crash in production).

**Prefer checking over `!`.** Dart promotes local variables after a null check, but **not fields**. Copy the field to a local first:

```dart
class User {
  User(this.name);
  final String name;
}

class ProfileController {
  User? user;

  // Avoid
  void printNameUnsafe() {
    if (user != null) print(user!.name);
  }

  // Prefer
  void printName() {
    final u = user;
    if (u != null) print(u.name); // promoted, no `!` needed
  }

  // Or with patterns (Dart 3+)
  void printNameWithPattern() {
    if (user case final u?) print(u.name);
  }
}
```

Use `!` only when null is truly impossible by design, and add a short comment saying why.

**Unused variables or parameters:** On Dart 3.7+, use the `_` wildcard. On older SDKs, rename to `_` / `__` or remove the variable.

### Types & Generics

- **Untyped collections:** Give empty literals an explicit type. Write `<int>[]`, `<String, dynamic>{}`, not `[]` or `{}`.
- **`List<dynamic>` assigned to `List<T>`:** Trace where the value is created and type it there. If it comes from JSON or another untyped source, convert it explicitly:
  ```dart
  List<int> parseIds(Map<String, dynamic> json) {
    // Option A: lazy view; fails later, when a bad element is read
    // return (json['ids'] as List).cast<int>();

    // Option B: checks every element now
    return (json['ids'] as List).map((e) => e as int).toList();
  }
  ```
- **Casts (`as T`):** Only cast when you know the runtime type matches. A wrong `as` compiles fine and throws a `TypeError` at runtime.
- **Strict modes:** `strict-casts`, `strict-inference`, and `strict-raw-types` (under `analyzer: language:`) catch implicit downcasts and hidden `dynamic` types. They're great for new projects, but in an existing project each can produce hundreds of new errors. **Suggest them in the report, one at a time, starting with `strict-casts`; don't turn them on yourself.**

### Method Overrides

Dart requires overrides to keep compatible types: return types can get narrower, and parameter types can get wider, never narrower.

If an override narrows a parameter type:

1. **First, question the design.** Usually the fix is to widen the subclass parameter to match the parent, or to make the parent class generic (`class Animal<T extends Prey>`).
2. **Use `covariant` only when narrowing is a deliberate domain rule** and callers are guaranteed to pass the right type. `covariant` turns the compile-time check into a runtime check, so a wrong argument becomes a crash.

### Error Handling in catch blocks

Apply these rules whenever a fix touches a `try`/`catch`:

The deciding question is **"can the app recover from this?"**, not the class name. Dart's convention is that `Exception` means a recoverable failure and `Error` means a bug, but it's a convention, not a compiler rule, and some packages don't follow it.

- **Catch `Exception` subtypes** for failures the app can recover from. Prefer specific types (`DioException`, `FormatException`, `FileSystemException`) over a bare `catch (e)`.
- **Never catch `Error` to hide a bug** (`TypeError`, `ArgumentError`, `StateError`, `LateInitializationError`, ...). Fix the code instead. The `avoid_catching_errors` lint enforces this.
- Use `rethrow`, not `throw e`, to pass an exception up. `rethrow` keeps the original stack trace.

There are two exceptions to the `Error` rule.

**1. A library uses `Error` for conditions outside your code's control.** For example, Hive throws `HiveError` (which extends `Error`) for programming mistakes like a missing adapter or an unopened box, but also for on-disk corruption ("Wrong checksum… Box may be corrupted"), which can happen on a user's device even when the code is correct. In that case:
- Catch the **specific** type (`on HiveError`), never `on Error` or a bare `catch`.
- Catch it **once, at the boundary** where recovery is possible (for example, where the box is opened), not around every call.
- **Filter, then `rethrow` everything else**, so real bugs still fail loudly in development.
- Only discard data that can be rebuilt (caches). If the data is irreplaceable (for example, unsynced orders), surface the error instead of deleting it.
- Suppress the lint on that line with a reason, following [When suppression is allowed](#when-suppression-is-allowed).

   ```dart
   Future<Box<CartItem>> openCartBox() async {
     try {
       return await Hive.openBox<CartItem>('cart');
       // ignore: avoid_catching_errors — Hive uses HiveError for on-disk corruption too
     } on HiveError catch (e) {
       if (!e.message.contains('corrupted')) rethrow; // real bugs still crash loudly
       await Hive.deleteBoxFromDisk('cart'); // safe: cart cache can be rebuilt
       return Hive.openBox<CartItem>('cart');
     }
   }
   ```

Before relying on this exception, check the library's source or docs to confirm which of its errors are environmental. Don't assume.

**2. Top-level handlers that catch everything only to report it.** Global handlers should catch all errors, including `Error`s, so they reach crash reporting instead of disappearing. They report; they don't recover or swallow.

   ```dart
   FlutterError.onError = (details) => crashReporter.recordFlutterError(details);
   PlatformDispatcher.instance.onError = (error, stack) {
     crashReporter.record(error, stack);
     return true;
   };
   ```

Anywhere else, a `catch` of an `Error` type is a bug to remove, and the fix belongs in the code that triggered it.

---

## Guardrails

These rules exist because each shortcut makes the error count drop without fixing anything.

- **Never** add `// ignore:` or `// ignore_for_file:` comments to hide a real problem. See [When suppression is allowed](#when-suppression-is-allowed) for the narrow exceptions.
- **Never** loosen `analysis_options.yaml` (removing lints, excluding source folders, lowering severity) to reduce errors. Excluding generated files is the one exception (see below).
- **Never** edit generated files. Fix the source and regenerate.
- **Never** delete code, tests, or features to make errors go away.
- **Never** change behavior just to satisfy the type checker. If the only fix changes behavior, ask first.
- **Don't** fix errors in unrelated files or packages beyond what was asked. List them in the report instead.

If the user explicitly asks for one of these (for example, "just ignore that lint for now"), do it, and record it in the report.

### When suppression is allowed

Suppression is acceptable in only two cases:

1. **Generated code.** Excluding generated files from analysis is standard practice, because nobody edits them by hand:
   ```yaml
   analyzer:
     exclude:
       - "**/*.g.dart"
       - "**/*.freezed.dart"
       - "**/*.config.dart"
       - "**/*.mocks.dart"
   ```
   Propose this in the report if generated files are producing diagnostics. Don't add it silently.

2. **A genuine false positive** in a lint (not an error), where the code is correct and the lint is wrong for this case. Then:
  - Suppress the **specific** diagnostic on the **specific** line: `// ignore: lint_name`. Never use `// ignore_for_file: type=lint`, which turns off every lint in the file.
  - Add a short reason on the same line or the line above, so reviewers know it was deliberate:
    ```dart
    // ignore: avoid_dynamic_calls — plugin returns untyped platform-channel map
    ```
  - For plugin diagnostics, prefix the plugin name (`// ignore: plugin_name/code`).
  - List every suppression in the final report.

   The `avoid_catching_errors` lint counts as a false positive only in the two cases described in [Error Handling in catch blocks](#error-handling-in-catch-blocks).

A type error, null-safety error, or invalid assignment is **never** a false positive. Fix the code.

---

## Final Report

End with a short summary the user can paste into a PR description:

```markdown
## Analyzer fixes

**Result:** 42 → 0 errors (2 warnings remaining)

**Automated (dart fix):** 18 fixes. Mostly `prefer_const_constructors` and unused imports.

**Generated code:** Re-ran build_runner. Fixed 9 "undefined _$Class" errors.

**Manual fixes:**
- `lib/features/cart/cart_cubit.dart`: initialized `items` in the constructor instead of `late`
- `lib/core/network/api_client.dart`: typed JSON list with `.map((e) => e as int)`

**Needs your decision:**
- `OrderModel.total`: nullable in the API but non-nullable in the UI. Should it default to 0 or show "N/A"?

**Suggestions:**
- Consider enabling `strict-casts` (would add ~30 errors right now)
```

Include all of: before → after count, what was automated, every manual fix with its file, any suppressions added (with reasons), anything that needs a human decision, and any guardrail exceptions the user approved.

---

## Examples

### Untyped list literal

```dart
// Error: List<dynamic> can't be assigned to List<int>
void printInts(List<int> a) => print(a);

void main() {
  final list = [];          // inferred as List<dynamic>
  list.add(1);
  printInts(list);
}
```

```dart
// Fixed
void main() {
  final list = <int>[];     // explicitly typed
  list.add(1);
  printInts(list);
}
```

### Uninitialized non-nullable field

```dart
// Error: Non-nullable instance field 'temperature' must be initialized
class Thermometer {
  String temperature;
  void read() => temperature = '20C';
}
```

Best: initialize it (no runtime risk).

```dart
class Thermometer {
  String temperature = 'unknown';
  void read() => temperature = '20C';
}
```

Also good: nullable, if "no reading yet" is a real state.

```dart
class Thermometer {
  String? temperature;
  void read() => temperature = '20C';
}
```

Avoid here: `late` crashes if anything reads `temperature` before `read()`.

```dart
class Thermometer {
  late String temperature;
  void read() => temperature = '20C';
}
```

### `late` used correctly (Flutter)

```dart
class _MapScreenState extends State<MapScreen> {
  late final MapController _controller;   // OK: always set in initState

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }
}
```

### Narrowed override parameter

```dart
// Error: parameter type 'Mouse' doesn't match the overridden 'Animal'
class Animal { void chase(Animal a) {} }
class Cat extends Animal {
  @override
  void chase(Mouse a) {}
}
```

Preferred: make the relationship explicit with generics.

```dart
class Animal<T> {
  void chase(T prey) {}
}

class Mouse extends Animal<Object> {}

class Cat extends Animal<Mouse> {
  @override
  void chase(Mouse a) {}
}
```

Acceptable only if narrowing is a deliberate rule. The type is now checked at runtime.

```dart
class Animal {
  void chase(Animal a) {}
}

class Mouse extends Animal {}

class Cat extends Animal {
  @override
  void chase(covariant Mouse a) {}
}
```

### Stale generated code

```text
error: Undefined name '_$UserFromJson'  (lib/models/user.dart:12)
```

Don't write `_$UserFromJson` by hand. Check that `part 'user.g.dart';` is present, then run:

```bash
dart run build_runner build --delete-conflicting-outputs
```
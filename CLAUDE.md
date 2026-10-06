# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## General Rules
Keep your replies concise, simple and short. Focus on conveying the key information. No unnecessary fluff, no long code snippets.

## Project Status

The app shell is in place: `main.dart`, dependency injection, theme and locale managers, the error-handling core, and the light/dark theme built from the Figma palette. The habits feature is not built yet. The only tests so far are the theme tests in `test/core/theme/`. The actual app to build is fully specified in `spec.md` — **read `spec.md` before writing any feature code**, it is the source of truth for requirements, architecture, and business rules.

### What's being built

A "Daily Habit Tracker" MVP: users create habits, mark daily completion, and see streaks. Offline-first, no auth/cloud sync/social features (see `spec.md` §1 for full non-goals).

## Commands

```bash
flutter pub get                 # install dependencies after editing pubspec.yaml
dart run build_runner build     # regenerate DI config after changing injectable classes
flutter gen-l10n                # regenerate AppLocalizations after changing ARB files
flutter run                     # run on a connected device/emulator
flutter analyze                 # static analysis (uses analysis_options.yaml / flutter_lints)
flutter test                    # run all tests
flutter test test/widget_test.dart          # run a single test file
flutter test --plain-name "test name"       # run a single test by name
flutter build apk / ios / linux / web       # platform builds
```

There is no CI config or build script beyond the standard Flutter toolchain. `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` and enables `avoid_catching_errors`.

## Architecture (per `spec.md`)

The app must follow **Clean Architecture** with this `lib/` layout:

```
lib/
├── core/
│   ├── base/                  # BaseResponse, SafeCallMixin (repository wrappers)
│   ├── constants/
│   ├── di/                    # get_it + injectable setup, ErrorHandlerModule
│   ├── errors/                # AppFailure, AppException, ErrorHandler, ExceptionMapper
│   │   ├── mappers/           # one ExceptionMapper per data source
│   │   └── presentation/      # AppFailure -> localized text (UI only)
│   ├── l10n/                  # ARB files, generated AppLocalizations
│   ├── secure_storage/
│   ├── theme/
│   └── route/
└── features/
    └── habits/
        ├── data/               # models, Hive datasources, repository implementations
        ├── domain/             # entities, repository interfaces, usecases
        └── presentation/       # cubit, screens, widgets
└── main.dart
```

Key decisions baked into the spec — don't deviate without checking with the user:

- **State management**: `flutter_bloc` Cubit (`HabitsCubit`), not raw Bloc. States: `HabitsInitial`, `HabitsLoading`, `HabitsLoaded(List<Habit>)`, `HabitsError(message)`. Use `provider` for simple view models / global app-level state (theme, locale) — Cubit stays for feature state.
- **Persistence**: Hive CE (via `hive_ce_flutter`), fully offline — no backend. `flutter_secure_storage` handles app settings (theme, language — backs `ThemeManager`/`LocaleManager`) and is reserved for future sensitive data (e.g. a PIN/passcode lock), kept separate from Hive's habit data.
- **Dependency injection**: `get_it` + `injectable` (code-generated registration).
- **Localization**: Flutter's official `gen-l10n` (ARB files in `lib/core/l10n/`, `l10n.yaml` config, generated `AppLocalizations`) — no third-party i18n package.
- **Navigation**: `go_router`, declarative named routes (`/`, `/habit/add`, `/habit/:id/edit`), push/pop only.
- **Habit entity fields**: `id` (uuid), `name`, `createdAt`, `completedDates` (list of normalized dates).
- **List item interactions**: tap checkbox toggles completion; swipe (via `flutter_slidable`) reveals Edit/Delete actions.

## Error handling

The architecture is set up. Skills in `.claude/skills/` describe how to use and extend it: `dart-error-handling-architecture` (setup in a new project), `dart-error-handling-add-data-source` (new data source or library upgrade), and `dart-safecall-repository-usage` (writing repository methods, and when not to use `safeCall`).

- Only repository implementations catch exceptions, through `safeCall` (returns `BaseResponse<T>`) or `safeCallOrNull` (returns `T?`, for fixed nullable signatures). Datasources and cubits don't add try/catch, so all mapping stays in one place.
- Every public repository method returns `BaseResponse<T>`, or a `Stream` of them, unless a documented exception applies.
- `AppFailure` is the only error type the domain and presentation layers see. Name its subclasses for what the user experiences (`CacheFailure`, not `HiveFailure`).
- Mappers implement `ExceptionMapper`, use `canHandle(Object)`, and must be mutually exclusive, so registration order never matters.
- Never catch an `Error` to hide a bug. Mappers may use narrow type tests (`exception is HiveError`), because Hive uses `Error` for recoverable conditions. Don't write `on Error` catch clauses.
- `details` is for logs only. `message` is only for text that is already user-safe, such as a backend-provided message.
- UI text comes from `failure.localized(l10n)` in `lib/core/errors/presentation/`. Nothing outside `presentation/` imports it.
- A new failure type needs a localizer case and an ARB key. The exhaustive switch in the localizer enforces this.

## Dependency injection and localization rules

- `@InjectableInit` keeps `allowMultipleRegistrations: true`, because mappers are registered `as: ExceptionMapper`.
- `ErrorHandler` is built only in `lib/core/di/error_handler_module.dart`, as a `@lazySingleton`. Don't change it to `@singleton`: that runs before the mappers are registered and yields an empty list.
- New mappers use `@Injectable(as: ExceptionMapper)`. Don't build an `ErrorHandler` by hand elsewhere.
- Regenerate instead of editing. Run `dart run build_runner build` for `*.config.dart`, and `flutter gen-l10n` after ARB changes. Never hand-edit generated files.

## Theme and colors

The palette comes from the Figma "Color Palette" frame. It lives in three files in `lib/core/theme/`: `app_colors.dart` (raw hex values), `app_theme_colors.dart` (`AppThemeColors` extension) and `app_theme.dart` (builds light and dark).

- Widgets never use `AppColors`, `Color(0x...)` or `Colors.*` (except `Colors.transparent`). Read colors from `Theme.of(context).colorScheme` or `context.appColors`, so light and dark both work. Only `lib/core/theme/` imports `app_colors.dart`.
- Don't branch on brightness in widgets (`Theme.of(context).brightness == ...`). If a color differs between modes, it belongs in the theme.
- Which role to use:
  - background → `surface`
  - main text → `onSurface`
  - secondary text → `onSurfaceVariant`
  - borders and unchecked checkbox → `outline`
  - primary blue → `primary`
  - FAB and progress card → `primaryContainer`
  - error and delete → `error` / `errorContainer`
  - completed state → `appColors.success` / `successContainer`
  - habit card → `appColors.habitSurface`
  - progress bar track → `appColors.progressTrack`
- Style components through the component themes in `AppTheme._build` (card, checkbox, FAB, input, dialog, progress), not per widget. Override in a widget only for a one-off.
- Text uses `Theme.of(context).textTheme` styles. Don't hardcode font sizes or text colors.
- A new design color needs:
  - a light and a dark constant in `AppColors`
  - a `ColorScheme` role in `_build` if one fits; otherwise a new `AppThemeColors` field, added to `light`, `dark`, `copyWith` and `lerp`
  - an assertion in `test/core/theme/app_theme_test.dart`
- Figma is the source of truth for colors. Change a hex value there first, then copy it to `AppColors`. Don't invent shades in code.
- Theme mode changes go only through `ThemeManager` (`setThemeMode` / `toggleTheme`), which saves the choice.

## Business rules that affect implementation

- Habit names must be unique.
- One completion record per calendar day — normalize timestamps to date-only before storing/comparing (see spec.md §7 Rule 3).
- Current streak counts backward, stopping at the first missed day; if today isn't completed yet, counting starts from yesterday (grace day, spec.md §7 Rule 4).
- Nothing resets at midnight. "Done today" is derived from `completedDates`. The home screen reloads on app resume and at local midnight when the date changed (spec.md §7 Rule 5).
- Name validation: required, ≤ 50 characters.

Full functional requirements, UI mockups, and the suggested build order are in `spec.md` §2–§13 — consult it directly rather than re-deriving requirements from scratch.

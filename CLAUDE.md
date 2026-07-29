# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## General Rules
Keep your replies concise, simple and short. Focus on conveying the key information. No unnecessary fluff, no long code snippets.

## Project Status

This is a **Flutter scaffold, not yet implemented**. `lib/main.dart` and `test/widget_test.dart` still contain the default `flutter create` counter template. The actual app to build is fully specified in `spec.md` — **read `spec.md` before writing any feature code**, it is the source of truth for requirements, architecture, and business rules.

### What's being built

A "Daily Habit Tracker" MVP: users create habits, mark daily completion, and see streaks. Offline-first, no auth/cloud sync/social features (see `spec.md` §1 for full non-goals).

## Commands

```bash
flutter pub get                 # install dependencies after editing pubspec.yaml
flutter run                     # run on a connected device/emulator
flutter analyze                 # static analysis (uses analysis_options.yaml / flutter_lints)
flutter test                    # run all tests
flutter test test/widget_test.dart          # run a single test file
flutter test --plain-name "test name"       # run a single test by name
flutter build apk / ios / linux / web       # platform builds
```

There is no CI config, custom lint rule set, or build script beyond the standard Flutter toolchain — `analysis_options.yaml` just includes `package:flutter_lints/flutter.yaml` with no overrides.

## Architecture (per `spec.md`)

The app must follow **Clean Architecture** with this `lib/` layout:

```
lib/
├── core/                      # constants, errors, utils shared across features
└── features/
    └── habits/
        ├── data/               # models, Hive datasources, repository implementations
        ├── domain/             # entities, repository interfaces, usecases
        └── presentation/       # cubit, screens, widgets
└── main.dart
```

Key decisions baked into the spec — don't deviate without checking with the user:

- **State management**: `flutter_bloc` Cubit (`HabitsCubit`), not raw Bloc. States: `HabitsInitial`, `HabitsLoading`, `HabitsLoaded(List<Habit>)`, `HabitsError(message)`.
- **Persistence**: Hive (via `hive_flutter`), fully offline — no backend.
- **Navigation**: `go_router`, declarative named routes (`/`, `/habit/add`, `/habit/:id/edit`), push/pop only.
- **Habit entity fields**: `id` (uuid), `name`, `createdAt`, `completedDates` (list of normalized dates).
- **List item interactions**: tap checkbox toggles completion; swipe (via `flutter_slidable`) reveals Edit/Delete actions.

### Business rules that affect implementation

- Habit names must be unique.
- One completion record per calendar day — normalize timestamps to date-only before storing/comparing (see spec.md §7 Rule 3).
- Current streak counts backward from today, stopping at the first missed day (spec.md §7 Rule 4).
- Name validation: required, ≤ 50 characters.

Full functional requirements, UI mockups, and the suggested build order are in `spec.md` §2–§13 — consult it directly rather than re-deriving requirements from scratch.

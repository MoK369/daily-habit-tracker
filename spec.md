# Technical Specification Document

## Daily Habit Tracker (MVP)

- **Version:** 1.0
- **Platform:** Flutter (Android & iOS)
- **Scope:** Simple MVP for learning Flutter architecture and AI-assisted development with Claude.

---

## 1. Project Overview

### Purpose

Daily Habit Tracker helps users build positive habits by allowing them to create habits and mark them as completed each day.

The application focuses on simplicity and offline-first functionality.

### Goals

- Allow users to create habits.
- Track daily completion status.
- Display current streaks.
- Store data locally.
- Provide a clean and responsive user experience.

### Non-Goals (Out of Scope for MVP)

- Authentication.
- Cloud sync.
- Social sharing.
- Habit groups.
- Advanced analytics.
- Widgets.
- Wearable support.

---

## 2. Functional Requirements

### FR-1: View Habits

**Description**

User can view all active habits.

**Acceptance Criteria**

- Habit list is displayed on the home screen.
- Empty state appears when no habits exist.

### FR-2: Create Habit

**Description**

User can create a new habit.

**Inputs**

- Habit Name (required)

**Validation**

- Name cannot be empty.
- Name length ≤ 50 characters.

**Acceptance Criteria**

- New habit appears immediately in the list.

### FR-3: Edit Habit

**Description**

User can edit an existing habit name.

**Acceptance Criteria**

- Updated name is reflected instantly.
- Existing history remains unchanged.

### FR-4: Delete Habit

**Description**

User can remove a habit.

**Acceptance Criteria**

- Habit is permanently removed.
- Completion history is removed.

### FR-5: Daily Completion

**Description**

User can mark a habit as completed for today.

**Acceptance Criteria**

- Habit can be toggled between completed and not completed.
- Status is saved locally.
- UI updates immediately.

### FR-6: Streak Calculation

**Description**

System calculates consecutive completed days.

**Rules**

- Completing today after yesterday increases streak.
- Missing a day resets streak.

**Acceptance Criteria**

- Current streak is displayed for each habit.

---

## 3. User Stories

### US-1

As a user, I want to create a habit, so that I can track it daily.

### US-2

As a user, I want to mark a habit as completed, so that I can build consistency.

### US-3

As a user, I want to see my streak, so that I stay motivated.

### US-4

As a user, I want to edit or delete habits, so that my list remains organized.

---

## 4. Application Architecture

### Architecture Style

Clean Architecture

```
lib/
│
├── core/
│   ├── constants/
│   ├── errors/
│   └── utils/
│
├── features/
│   └── habits/
│       ├── data/
│       │   ├── models/
│       │   ├── datasources/
│       │   └── repositories/
│       │
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       │
│       └── presentation/
│           ├── cubit/
│           ├── screens/
│           └── widgets/
│
└── main.dart
```

---

## 5. State Management

### Solution

Flutter Bloc (Cubit) for feature state, plus `provider` for simple view models / global app-level state (e.g. theme mode, locale) that doesn't need Bloc's event/state ceremony.

### HabitsCubit Responsibilities

- Load habits
- Add habit
- Edit habit
- Delete habit
- Toggle completion
- Calculate streaks

### States

- `HabitsInitial`
- `HabitsLoading`
- `HabitsLoaded` — `List<Habit>`
- `HabitsError` — `message`

---

## 6. Data Storage

### Local Database

Hive CE (Community Edition fork of Hive, more actively maintained)

**Reason**

- Lightweight
- Fast
- Works offline
- Flutter-friendly

### Habit Entity

```
Habit
├── id
├── name
├── createdAt
└── completedDates
```

### Fields

| Field          | Type         |
|----------------|--------------|
| id             | String       |
| name           | String       |
| createdAt      | DateTime     |
| completedDates | `List<Date>` |

### App Settings & Sensitive Data

`flutter_secure_storage` (separate from Hive CE, which only stores habit data):

- Persists app-level settings (theme mode, selected language) across restarts — backs `ThemeManager`/`LocaleManager`.
- Reserved for future sensitive data (e.g. a PIN/passcode app lock) — not implemented in the MVP, but the storage layer is in place for it.

---

## 7. Business Rules

### Rule 1

Habit names must be unique.

### Rule 2

A habit can only have one completion record per day.

Example:

```
2026-07-29 ✅
2026-07-29 ✅
```

Should be stored only once.

### Rule 3

Dates should be normalized.

Example:

```
2026-07-29 09:00
2026-07-29 18:00
```

Stored as:

```
2026-07-29
```

### Rule 4

Current streak starts from today and moves backward until a missed day is found.

Example:

```
Today       ✅
Yesterday   ✅
2 days ago  ✅
3 days ago  ❌
```

Result:

```
Current Streak = 3
```

---

## 8. UI Specification

### Screen 1: Home Screen

**Components**

- AppBar
- Habit list
- Floating Action Button
- Empty state

**Habit Item**

```
---------------------------------
Read Books

🔥 Streak: 5

[✓]
---------------------------------
```

**Actions**

- Tap checkbox → toggle completion.
- Swipe habit item (via `flutter_slidable`) → reveal **Edit** and **Delete** action buttons.
  - Tap **Edit** → navigate to Add/Edit Habit screen.
  - Tap **Delete** → remove habit (with confirmation).

### Screen 2: Add/Edit Habit

**Components**

```
Habit Name

[________________]

[Save]
```

**Validation**

- Required field.
- Max length 50.

---

## 9. Navigation

Navigation is handled with **`go_router`**, using declarative, named routes.

```
/                 → Home Screen
/habit/add        → Add Habit Screen
/habit/:id/edit    → Edit Habit Screen
```

- Home Screen navigates to Add/Edit Habit Screen via `context.push(...)`.
- Add/Edit Habit Screen returns to Home Screen via `context.pop()`.

---

## 10. Error Handling

### Storage Failure

Display:

> Something went wrong.
> Please try again.

### Empty Habit Name

Display:

> Habit name is required.

---

## 11. Dependencies

| Package                  | Purpose                                                     |
|--------------------------|-------------------------------------------------------------|
| `flutter_bloc`           | State management (Cubit) for feature state                  |
| `provider`               | Simple view models / global app-level state (theme, locale) |
| `equatable`              | Value equality for states/entities                          |
| `hive_ce`                | Local database (Hive CE fork)                               |
| `hive_ce_flutter`        | Hive CE integration with Flutter                            |
| `path_provider`          | Resolving local storage paths for Hive                      |
| `uuid`                   | Generating unique habit IDs                                 |
| `go_router`              | App navigation and routing                                  |
| `flutter_slidable`       | Swipe-to-edit / swipe-to-delete on habit list items         |
| `get_it`                 | Service locator for dependency injection                    |
| `injectable`             | Code generation for `get_it` DI registration                |
| `flutter_localizations`  | Flutter SDK localization delegates                          |
| `intl`                   | Date/number formatting used by generated `AppLocalizations` |
| `flutter_secure_storage` | App settings (theme, language) and future sensitive data    |

---

## 12. Theme

Material Design 3

### Light Theme

- Primary: Blue
- Success: Green
- Background: White

### Dark Theme

- Primary: Blue
- Background: Dark Gray

---

## 13. Localization

Flutter's official **gen-l10n** codegen, not a third-party i18n package.

- ARB source files under `lib/l10n/` (`app_en.arb` as the template locale).
- `l10n.yaml` at project root configures `gen-l10n` (output dir, template file).
- Generates `AppLocalizations` — accessed via `AppLocalizations.of(context)!`.
- App and MaterialApp wired with `AppLocalizations.localizationsDelegates` and `AppLocalizations.supportedLocales`.
- MVP ships with `en` only; structure supports adding locales later without code changes.

---

## 14. MVP Success Criteria

The MVP is considered complete when:

- ✅ User can create a habit.
- ✅ User can edit a habit.
- ✅ User can delete a habit.
- ✅ User can mark today's completion.
- ✅ Current streak is calculated correctly.
- ✅ Data persists after app restart.
- ✅ Works completely offline.

### Suggested Development Order

1. Setup project structure.
2. Configure Hive CE.
3. Create Habit model/entity.
4. Implement local datasource.
5. Implement repository.
6. Create use cases.
7. Implement Cubit.
8. Build Home Screen.
9. Build Add/Edit Screen.
10. Add streak calculation.
11. Add validations.
12. Test persistence and edge cases.

---

_This specification is intentionally small but realistic, making it an excellent foundation for practicing Clean Architecture, Bloc, Hive CE, and Claude-driven Flutter development._

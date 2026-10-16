---
name: flutter-widget-best-practices
description: Rules and best practices for writing, splitting and reviewing Flutter widgets in this project, including size limits (a widget class is at most 200 lines and a widget file at most 300 lines), keeping build() cheap, localizing setState, const constructors, widget classes instead of helper methods, child-instance reuse in builders, BlocBuilder/BlocSelector rebuild scoping, theme and l10n use, lists, lifecycle and widget tests. Use this skill whenever the user creates or edits a screen, page, widget, dialog, list item or build method, asks to extract or split UI, says a widget or file is too big, sees jank or too many rebuilds, or asks for a widget review. Use it even when the user only says "build the UI" or "add a screen" and doesn't mention best practices.
model: claude-sonnet-5
---

# Flutter Widget Best Practices

Widgets are exempt from the 20-line function rule in `CLAUDE.md`. They follow this skill instead. The goal is widgets that are small, cheap to rebuild and easy to read. Most of the performance rules come from the Flutter docs ["Control build() cost"](https://docs.flutter.dev/perf/best-practices#control-build-cost).

## 1. Size limits (hard rules)

| Unit                                                                                                  | Limit           |
|-------------------------------------------------------------------------------------------------------|-----------------|
| One widget class (`StatelessWidget`, `StatefulWidget`, or its `State` class, each counted on its own) | **≤ 200 lines** |
| One widget file (imports and private helpers included)                                                | **≤ 300 lines** |

- Generated files are exempt.
- Treat 150 lines per class and 250 per file as the point to start splitting. Don't wait until the limit is hit.
- A `build` method should read like an outline of the layout. If you have to scroll to understand it, extract named widgets.
- When a file gets too big, move the extracted widgets to their own files in `presentation/widgets/`. Small private widgets (`_HabitStreakBadge`) can stay in the same file while it is under the limit.
- Check with `wc -l <file>` before you finish.

## 2. Control build() cost

`build()` can run on every frame of an animation and every time an ancestor rebuilds. Keep it cheap and keep its rebuilds small.

**No costly or repeated work in `build`.** Don't sort, filter, compute streaks or do date math there, and don't create `DateFormat`, controllers, `FocusNode`s or futures. Compute values in the cubit or state, or once in `initState` / `didChangeDependencies`, and have `build` only read them.

```dart
// Bad: recalculated on every rebuild, and it is business logic in a widget.
final streak = computeStreak(habit.completedDates);
// Good: the cubit/entity already exposes it.
Text(l10n.streakDays(habit.currentStreak));
```

**Split big widgets by encapsulation and by how they change.** Parts that change together go in one widget. Parts that change on their own (a checkbox, a progress bar, a timer) get their own widget so they rebuild alone.

**Localize `setState`.** Calling `setState` rebuilds every descendant of that `State`. Push the state down into the smallest `StatefulWidget` that actually changes. Don't make a whole screen stateful for one toggle.

**Reuse unchanged child instances.** Rebuilding stops when Flutter meets the same widget instance as in the previous frame. Builders take a `child` argument for this: build the static part once and pass it through, as `SlideTransition` and the `TransitionBuilder` pattern do.

```dart
ValueListenableBuilder<bool>(
  valueListenable: _expanded,
  child: const HabitDetails(),           // built once
  builder: (context, expanded, child) =>
      expanded ? child! : const SizedBox.shrink(),
);
```

Use `ListenableBuilder` for a `ChangeNotifier`, `ValueListenableBuilder` for a `ValueNotifier` and `AnimatedBuilder` for an `Animation`. Don't override `operator ==` on widgets to force this. It makes comparisons O(N²) and is a known pitfall.

**Use `const` constructors wherever you can.** A `const` widget is canonicalized, so Flutter skips most of its rebuild work. Give every widget a `const` constructor with `super.key`, and mark const literals. `prefer_const_constructors` and its related lints in `analysis_options.yaml` flag the missed ones.

**Use widget classes, not helper methods.** For a reusable or separable piece of UI, write a `StatelessWidget`, not `Widget _buildHeader()`. A class gets its own `Element`, can be `const`, rebuilds on its own and shows up in DevTools. A helper method rebuilds with its parent every time.

```dart
// Bad
Widget _buildHeader(BuildContext context) => ...;
// Good
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();
  ...
}
```

## 3. State management in widgets

- Feature state comes from `HabitsCubit`. App-level state (theme, locale) comes from `provider`. Widgets don't call repositories, datasources or usecases directly.
- Narrow your rebuilds:
  - `BlocBuilder` with `buildWhen: (prev, curr) => ...` when only some state changes matter.
  - `BlocSelector` / `context.select` to rebuild on one value, such as a single habit or a count. Selected values must be immutable or have value equality.
  - Put the builder as low in the tree as possible, not around the whole `Scaffold`.
- Side effects (snackbars, navigation, dialogs) are UI events from `BaseCubit`, handled by `UiEventHandlerMixin` on the screen's `State` (subscribed in `initState`). Don't use `BlocListener`/`BlocConsumer` for them, and never trigger them in `builder`.
- Use `context.read` in callbacks and `context.watch`/`select` only inside `build`.
- No business rules in widgets: no validation logic, streak math or date normalization. Widgets show state and forward user intent to the cubit.

## 4. Theme, text and localization

Follow the "Theme and colors" section of `CLAUDE.md`. In short:

- Colors come from `Theme.of(context).colorScheme` or `context.appColors`. Never use `AppColors`, `Color(0x…)` or `Colors.*` (except `Colors.transparent`), and don't branch on brightness.
- Text uses `Theme.of(context).textTheme`. No hardcoded font sizes or text colors.
- Style components through `AppTheme` component themes. Override per widget only for a one-off.
- Use `color.withValues(alpha: …)`, not the deprecated `withOpacity`.
- Every user-visible string comes from `AppLocalizations`. Failures are shown with `failure.localized(l10n)`.
- Read `Theme.of(context)` and `AppLocalizations.of(context)` once at the top of `build` into locals. Don't look them up repeatedly.

## 5. Lists and layout

- Use `ListView.builder` (or `.separated`) for habit lists so items are built lazily. Avoid `ListView(children: list.map(...).toList())` for data of unknown size.
- Give list items a stable key: `ValueKey(habit.id)`. `Slidable` needs one, especially for dismissible items. Never use the index as the key for items that can be deleted or reordered.
- Avoid `shrinkWrap: true` and nested scrollables. Use slivers (`CustomScrollView`) to combine a header and a list.
- Avoid `Opacity`, `ClipRRect`/`saveLayer` effects and `IntrinsicHeight`/`IntrinsicWidth` in lists and animations. Prefer `AnimatedOpacity`/`FadeTransition` and fixed or flex layouts.
- Prefer the specific widget over `Container`: `ColoredBox`, `DecoratedBox`, `Padding`, `SizedBox` (`use_colored_box`, `use_decorated_box`).
- Use `SizedBox` for gaps, and shared spacing constants from `core/constants/`, not magic numbers scattered around.
- Support small screens and large text: no fixed heights on text containers, and use `Flexible`/`Expanded` with `overflow: TextOverflow.ellipsis` for long habit names.

## 6. Lifecycle and resources

- Create controllers, `FocusNode`s and subscriptions in `initState` and dispose them in `dispose`. Never create them in `build`.
- After an `await`:
  - In a `State`, check `if (!mounted) return;`.
  - With any other `BuildContext` (a callback argument, a `StatelessWidget`), check `if (!context.mounted) return;`.
  - Or capture `Navigator.of(context)` / `ScaffoldMessenger.of(context)` before the `await`.
- Every widget constructor takes `super.key` and is `const` when it can be.

## 7. Structure and naming

- One public widget per file. The file name is the snake_case class name (`habit_list_item.dart` → `HabitListItem`).
- Full pages go in `features/<feature>/presentation/screens/` and pieces in `presentation/widgets/`. Widgets shared across features go in `core/` (for example `core/widgets/`).
- Pass in only the data a widget needs (a `Habit`, a `bool`, a callback), not the whole state or cubit. That keeps it reusable, `const`-friendly and easy to test.
- Name callbacks for intent: `onToggle`, `onEdit`, `onDelete`.

## 8. Testing

- Write widget tests for important interactions: toggling the checkbox, the slidable edit/delete actions, form validation messages, and the empty, loading and error states.
- Mock the cubit and pump the widget inside a `MaterialApp` with `AppTheme` light/dark and the `AppLocalizations` delegates, so theme and l10n lookups work.
- Find widgets by key or semantics, not by hardcoded English text.
- Small pure-display widgets don't each need a test. Cover screens and interactive widgets first.

## 9. Review checklist

Before finishing any widget work, confirm:

- [ ] Each widget class ≤ 200 lines and each file ≤ 300 lines (`wc -l`).
- [ ] `build` does no sorting, filtering, date math or object creation.
- [ ] `setState` / `BlocBuilder` scope is the smallest subtree that changes.
- [ ] Static subtrees are `const` or passed as a builder `child`.
- [ ] No `Widget _buildX()` helpers. Extracted UI is a widget class.
- [ ] Colors, text styles and strings come from the theme and `AppLocalizations`.
- [ ] List items use `ListView.builder` and stable `ValueKey`s.
- [ ] Controllers are disposed, and `mounted`/`context.mounted` is checked after every `await`.
- [ ] `flutter analyze` is clean, and widget tests pass for interactive pieces.

import 'package:claude_code/core/base/presentation/base_cubit.dart';
import 'package:claude_code/core/base/presentation/base_ui_event.dart';
import 'package:claude_code/core/base/presentation/ui_event_handler_mixin.dart';
import 'package:claude_code/core/errors/app_failure.dart';
import 'package:claude_code/core/l10n/app_localizations.dart';
import 'package:claude_code/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

sealed class TestUiEvent extends BaseUiEvent {
  const TestUiEvent();
}

final class Ping extends TestUiEvent {
  const Ping();
}

enum TestMessage implements UiMessage { saved, welcome }

class TestCubit extends BaseCubit<int, TestUiEvent> {
  TestCubit() : super(0);

  void ping() => emitUiEvent(const Ping());
  void success() => showSuccess(TestMessage.saved);
  void info() => showInfo(TestMessage.welcome);
  void error() => showError(const DuplicateNameFailure());
  void openDetails() => navigateTo('/details');
  void goHome() => replaceWith('/');
  void back() => navigateBack(result: 'done');
  void bump() => emit(state + 1);
}

class TestScreen extends StatefulWidget {
  const TestScreen({required this.cubit, required this.onPing, super.key});

  final TestCubit cubit;
  final VoidCallback onPing;

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen>
    with UiEventHandlerMixin<TestScreen, TestUiEvent> {
  @override
  BaseCubit<Object?, TestUiEvent> get uiEventCubit => widget.cubit;

  @override
  void onCustomUiEvent(TestUiEvent event) => switch (event) {
    Ping() => widget.onPing(),
  };

  @override
  String localizeMessage(UiMessage message, AppLocalizations l10n) =>
      switch (message as TestMessage) {
        TestMessage.saved => 'Saved',
        TestMessage.welcome => l10n.appTitle,
      };

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('screen'));
}

void main() {
  late TestCubit cubit;
  late int pings;

  setUp(() {
    cubit = TestCubit();
    pings = 0;
  });
  tearDown(() => cubit.close());

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
          routes: [
            GoRoute(
              path: 'details',
              builder: (_, _) =>
                  TestScreen(cubit: cubit, onPing: () => pings++),
            ),
          ],
        ),
      ],
      initialLocation: '/details',
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> send(WidgetTester tester, VoidCallback action) async {
    action();
    await tester.pumpAndSettle();
  }

  testWidgets('shows success and info snackbars', (tester) async {
    await pumpApp(tester);
    await send(tester, cubit.success);
    expect(find.text('Saved'), findsOneWidget);
    await send(tester, cubit.info);
    expect(find.text('Daily Habit Tracker'), findsOneWidget);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('shows the localized failure text', (tester) async {
    await pumpApp(tester);
    await send(tester, cubit.error);
    expect(find.text('A habit with this name already exists.'), findsOneWidget);
  });

  testWidgets('routes custom events to onCustomUiEvent once', (tester) async {
    await pumpApp(tester);
    await send(tester, cubit.ping);
    await send(tester, cubit.bump);
    expect(pings, 1);
  });

  testWidgets('navigates back and replaces the route', (tester) async {
    final router = await pumpApp(tester);
    await send(tester, cubit.back);
    expect(find.text('home'), findsOneWidget);
    router.go('/details');
    await tester.pumpAndSettle();
    await send(tester, cubit.goHome);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('pushes a new route', (tester) async {
    final router = await pumpApp(tester);
    router.go('/');
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    router.go('/details');
    await tester.pumpAndSettle();
    await send(tester, cubit.openDetails);
    expect(find.text('screen', skipOffstage: false), findsNWidgets(2));
  });

  testWidgets('stops handling events after dispose', (tester) async {
    await pumpApp(tester);
    await tester.pumpWidget(const SizedBox());
    await send(tester, cubit.ping);
    expect(pings, 0);
  });
}

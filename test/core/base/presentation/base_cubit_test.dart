import 'package:claude_code/core/base/presentation/base_cubit.dart';
import 'package:claude_code/core/base/presentation/base_ui_event.dart';
import 'package:claude_code/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class TestUiEvent extends BaseUiEvent {
  const TestUiEvent();
}

final class Ping extends TestUiEvent {
  const Ping();
}

enum TestMessage implements UiMessage { saved }

class TestCubit extends BaseCubit<int, TestUiEvent> {
  TestCubit() : super(0);

  void sendAll() {
    emitUiEvent(const Ping());
    showSuccess(TestMessage.saved);
    showInfo(TestMessage.saved);
    showError(const CacheFailure());
    navigateTo('/a', extra: 1);
    replaceWith('/b');
    navigateBack(result: true);
  }
}

void main() {
  late TestCubit cubit;

  setUp(() => cubit = TestCubit());
  tearDown(() => cubit.close());

  test('delivers custom and common events in order', () async {
    final expectation = expectLater(
      cubit.uiEvents,
      emitsInOrder(<Matcher>[
        isA<Ping>(),
        isA<ShowSuccessMessage>().having(
          (e) => e.message,
          'message',
          TestMessage.saved,
        ),
        isA<ShowInfoMessage>(),
        isA<ShowErrorMessage>(),
        isA<NavigateTo>()
            .having((e) => e.location, 'location', '/a')
            .having((e) => e.extra, 'extra', 1),
        isA<ReplaceWith>().having((e) => e.location, 'location', '/b'),
        isA<NavigateBack>().having((e) => e.result, 'result', true),
      ]),
    );
    cubit.sendAll();
    await expectation;
  });

  test('does not change state when sending UI events', () {
    cubit.sendAll();
    expect(cubit.state, 0);
  });

  test('closes the event stream on close and ignores later events', () async {
    final done = expectLater(cubit.uiEvents, emitsDone);
    await cubit.close();
    await done;
    expect(cubit.sendAll, returnsNormally);
  });

  test('supports more than one listener', () async {
    final first = expectLater(cubit.uiEvents, emits(isA<Ping>()));
    final second = expectLater(cubit.uiEvents, emits(isA<Ping>()));
    cubit.sendAll();
    await Future.wait([first, second]);
  });
}

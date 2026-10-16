import '../../errors/app_failure.dart';

/// Not `sealed`: screens extend it from their own libraries.
abstract class BaseUiEvent {
  const BaseUiEvent();
}

/// Message key a cubit emits; the screen turns it into localized text.
abstract interface class UiMessage {}

sealed class CommonUiEvent extends BaseUiEvent {
  const CommonUiEvent();
}

final class ShowSuccessMessage extends CommonUiEvent {
  const ShowSuccessMessage(this.message);

  final UiMessage message;
}

final class ShowInfoMessage extends CommonUiEvent {
  const ShowInfoMessage(this.message);

  final UiMessage message;
}

final class ShowErrorMessage extends CommonUiEvent {
  const ShowErrorMessage(this.failure);

  final AppFailure failure;
}

final class NavigateTo extends CommonUiEvent {
  const NavigateTo(this.location, {this.extra});

  final String location;
  final Object? extra;
}

final class ReplaceWith extends CommonUiEvent {
  const ReplaceWith(this.location, {this.extra});

  final String location;
  final Object? extra;
}

final class NavigateBack extends CommonUiEvent {
  const NavigateBack({this.result});

  final Object? result;
}

/// Type argument for screens without custom UI events.
final class NoCustomUiEvent extends BaseUiEvent {
  const NoCustomUiEvent._();
}

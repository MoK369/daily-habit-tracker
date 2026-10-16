import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/app_failure.dart';
import 'base_ui_event.dart';

/// State is for rebuilds only; one-shot effects go through [uiEvents].
abstract class BaseCubit<S, E extends BaseUiEvent> extends Cubit<S> {
  BaseCubit(super.initialState);

  // Broadcast so a remounted screen can listen again.
  final StreamController<BaseUiEvent> _uiEventController =
      StreamController<BaseUiEvent>.broadcast();

  Stream<BaseUiEvent> get uiEvents => _uiEventController.stream;

  @protected
  void emitUiEvent(E event) => _add(event);

  @protected
  void showSuccess(UiMessage message) => _add(ShowSuccessMessage(message));

  @protected
  void showInfo(UiMessage message) => _add(ShowInfoMessage(message));

  @protected
  void showError(AppFailure failure) => _add(ShowErrorMessage(failure));

  @protected
  void navigateTo(String location, {Object? extra}) =>
      _add(NavigateTo(location, extra: extra));

  @protected
  void replaceWith(String location, {Object? extra}) =>
      _add(ReplaceWith(location, extra: extra));

  @protected
  void navigateBack({Object? result}) => _add(NavigateBack(result: result));

  void _add(BaseUiEvent event) {
    if (isClosed) return;
    _uiEventController.add(event);
  }

  @override
  Future<void> close() async {
    await _uiEventController.close();
    return super.close();
  }
}

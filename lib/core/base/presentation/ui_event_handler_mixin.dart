import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../errors/presentation/app_failure_localizer.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme_colors.dart';
import 'base_cubit.dart';
import 'base_ui_event.dart';

/// Handles a [BaseCubit]'s UI events, subscribed in `initState`.
/// Screens override [onCustomUiEvent] and [localizeMessage] when needed.
mixin UiEventHandlerMixin<W extends StatefulWidget, E extends BaseUiEvent>
    on State<W> {
  StreamSubscription<BaseUiEvent>? _uiEventSubscription;

  BaseCubit<Object?, E> get uiEventCubit;

  @override
  void initState() {
    super.initState();
    _uiEventSubscription = uiEventCubit.uiEvents.listen(_onUiEvent);
  }

  @override
  void dispose() {
    unawaited(_uiEventSubscription?.cancel());
    super.dispose();
  }

  void _onUiEvent(BaseUiEvent event) {
    if (!mounted) return;
    switch (event) {
      case final CommonUiEvent common:
        handleCommonUiEvent(common);
      case final E custom:
        onCustomUiEvent(custom);
      default:
        assert(false, 'Unexpected UI event: ${event.runtimeType}');
    }
  }

  void onCustomUiEvent(E event) {
    assert(false, 'Override onCustomUiEvent to handle ${event.runtimeType}');
  }

  String localizeMessage(UiMessage message, AppLocalizations l10n) {
    assert(false, 'Override localizeMessage to handle ${message.runtimeType}');
    return '';
  }

  void handleCommonUiEvent(CommonUiEvent event) {
    final l10n = AppLocalizations.of(context)!;
    switch (event) {
      case ShowSuccessMessage(:final message):
        showSuccessMessage(localizeMessage(message, l10n));
      case ShowInfoMessage(:final message):
        showInfoMessage(localizeMessage(message, l10n));
      case ShowErrorMessage(:final failure):
        showErrorMessage(failure.localized(l10n));
      case NavigateTo(:final location, :final extra):
        unawaited(context.push<Object?>(location, extra: extra));
      case ReplaceWith(:final location, :final extra):
        context.go(location, extra: extra);
      case NavigateBack(:final result):
        navigateBack(result);
    }
  }

  void showSuccessMessage(String message) {
    final colors = context.appColors;
    _showSnackBar(message, colors.successContainer, colors.success);
  }

  void showInfoMessage(String message) => _showSnackBar(message);

  void showErrorMessage(String message) {
    final scheme = Theme.of(context).colorScheme;
    _showSnackBar(message, scheme.errorContainer, scheme.onErrorContainer);
  }

  void navigateBack(Object? result) {
    if (context.canPop()) context.pop(result);
  }

  void _showSnackBar(String message, [Color? background, Color? foreground]) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          content: Text(message, style: TextStyle(color: foreground)),
        ),
      );
  }
}

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../errors/exceptions.dart';
import '../secure_storage/secure_storage_keys.dart';
import '../secure_storage/secure_storage_service.dart';

@singleton
class ThemeManager extends ChangeNotifier {
  ThemeManager(this._secureStorageService);

  final SecureStorageService _secureStorageService;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    try {
      final stored = await _secureStorageService.read(
        key: SecureStorageKeys.themeMode,
      );
      if (stored == null) return;
      _themeMode = ThemeMode.values.byName(stored);
      notifyListeners();
    } on SecureStorageException {
      // Keep the default theme mode if the stored value can't be read.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await _secureStorageService.write(
        key: SecureStorageKeys.themeMode,
        value: mode.name,
      );
    } on SecureStorageException {
      // In-memory state already updated; persistence failure is non-fatal.
    }
  }

  Future<void> toggleTheme() {
    return setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

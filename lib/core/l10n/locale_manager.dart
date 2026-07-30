import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../errors/exceptions.dart';
import '../secure_storage/secure_storage_keys.dart';
import '../secure_storage/secure_storage_service.dart';
import 'app_language.dart';

@singleton
class LocaleManager extends ChangeNotifier {
  LocaleManager(this._secureStorageService);

  final SecureStorageService _secureStorageService;

  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;

  Locale get locale => Locale(_language.code);

  Future<void> init() async {
    try {
      final stored = await _secureStorageService.read(
        key: SecureStorageKeys.language,
      );
      if (stored == null) return;
      _language = stored.toAppLanguage();
      notifyListeners();
    } on SecureStorageException {
      // Keep the default language if the stored value can't be read.
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    try {
      await _secureStorageService.write(
        key: SecureStorageKeys.language,
        value: language.label,
      );
    } on SecureStorageException {
      // In-memory state already updated; persistence failure is non-fatal.
    }
  }
}

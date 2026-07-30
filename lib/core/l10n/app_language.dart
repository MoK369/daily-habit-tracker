enum AppLanguage { english, arabic }

extension AppLanguageX on AppLanguage {
  String get label => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.arabic => 'العربية',
  };

  String get code => switch (this) {
    AppLanguage.english => 'en',
    AppLanguage.arabic => 'ar',
  };
}

extension AppLanguageLabelX on String {
  AppLanguage toAppLanguage() => AppLanguage.values.firstWhere(
    (language) => language.label == this,
    orElse: () => AppLanguage.english,
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await Future.wait([
    getIt<ThemeManager>().init(),
    getIt<LocaleManager>().init(),
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: getIt<ThemeManager>()),
        ChangeNotifierProvider.value(value: getIt<LocaleManager>()),
      ],
      child: Consumer2<ThemeManager, LocaleManager>(
        builder: (context, themeManager, localeManager, _) {
          return MaterialApp(
            title: AppConstants.appTitle,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeManager.themeMode,
            locale: localeManager.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WelcomePage(),
          );
        },
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Welcome to Our App',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

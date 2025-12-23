import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/locale_provider.dart';
import 'presentation/router.dart';
import 'data/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix any billing cycles with incorrect interest calculations
  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.fixInterestCalculations();
  } catch (e) {
    // Ignore initialization errors to prevent app crash
    debugPrint('Database init error: $e');
  }

  runApp(const ProviderScope(child: PrestamosApp()));
}

/// Main app widget with dynamic theme and locale support
class PrestamosApp extends ConsumerWidget {
  const PrestamosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode for reactive updates
    final themeMode = ref.watch(themeModeProvider);
    // Watch locale for reactive updates
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'PrestamosApp',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocales.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}

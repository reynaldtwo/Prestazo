import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/locale_provider.dart';
import 'presentation/router.dart';
import 'data/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' as io;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Desktop (Windows/Linux/MacOS)
  if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Fix any billing cycles with incorrect interest calculations
  // try {
  //   final dbHelper = DatabaseHelper();
  //   await dbHelper.fixInterestCalculations();
  // } catch (e) {
  //   // Ignore initialization errors to prevent app crash
  //   debugPrint('Database init error: $e');
  // }

  // Catch Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Custom error widget for release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error de Aplicación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              details.exception.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  };

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

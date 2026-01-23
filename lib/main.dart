import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestamos_app/core/localization/locale_provider.dart';
import 'package:prestamos_app/core/theme/theme_provider.dart';
import 'package:prestamos_app/presentation/router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Desktop (Windows/Linux/MacOS)
  if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Catch Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Error log for debugging
    debugPrint('[Flutter Engine Error] ${details.exception}');
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
            const Text(
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

/// Widget principal de la aplicación con soporte para tema dinámico y localización.
class PrestamosApp extends ConsumerWidget {
  /// Crea una instancia de [PrestamosApp].
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
      localeResolutionCallback: (locale, supportedLocales) {
        // 1. Check for more specific match (languageCode + countryCode)
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode &&
              supportedLocale.countryCode == locale?.countryCode) {
            return supportedLocale;
          }
        }

        // 2. Check for language code match
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }

        // 3. Fallback to English (Default)
        return AppLocales.en;
      },
      routerConfig: appRouter,
    );
  }
}

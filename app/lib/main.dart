import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/database.dart';
import 'core/services/database_provider.dart';
import 'core/services/lang_mode_provider.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Read prefs synchronously — fast
  final prefs = await SharedPreferences.getInstance();
  final storedLang  = prefs.getString('sinosphere_lang_mode');
  final storedTheme = prefs.getString('sinosphere_theme_mode');
  if (storedLang == 'korean')  LangModeNotifier.cached = LangMode.korean;
  if (storedTheme == 'dark')   ThemeModeNotifier.cached = ThemeMode.dark;
  if (storedTheme == 'light')  ThemeModeNotifier.cached = ThemeMode.light;
  if (storedTheme == 'system') ThemeModeNotifier.cached = ThemeMode.system;

  await initNotifications();

  // Show app immediately with loading screen — DB loads in background
  // This lets the native splash transition smoothly and shows splashscreen
  // while the 93MB DB is being copied on first install
  runApp(const _LoadingApp());

  // Copy DB in background (only on first install)
  final db = await openDatabase();

  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  notificationContainer = container;

  // Replace loading app with real app
  runApp(UncontrolledProviderScope(
    container: container,
    child: const SinosphereApp(),
  ));

  scheduleWordOfDay(container);
}

/// Shown while DB is loading — matches splashscreen colors exactly
class _LoadingApp extends StatelessWidget {
  const _LoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/splashscreen.png',
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.contain),
          ]),
        ),
      ),
    );
  }
}


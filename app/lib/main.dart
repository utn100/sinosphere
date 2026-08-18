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

  // Load preferences AND database before first runApp — no splash flash
  final prefsFuture = SharedPreferences.getInstance();
  final dbFuture    = openDatabase();

  final prefs = await prefsFuture;
  final storedLang  = prefs.getString('sinosphere_lang_mode');
  final storedTheme = prefs.getString('sinosphere_theme_mode');
  if (storedLang == 'korean')  LangModeNotifier.cached = LangMode.korean;
  if (storedTheme == 'dark')   ThemeModeNotifier.cached = ThemeMode.dark;
  if (storedTheme == 'light')  ThemeModeNotifier.cached = ThemeMode.light;
  if (storedTheme == 'system') ThemeModeNotifier.cached = ThemeMode.system;

  final db = await dbFuture;

  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  notificationContainer = container;

  await initNotifications();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const SinosphereApp(),
  ));

  // Schedule daily word notification after app is running
  scheduleWordOfDay(container);
}

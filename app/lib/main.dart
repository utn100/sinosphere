import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/database.dart';
import 'core/services/database_provider.dart';
import 'core/services/lang_mode_provider.dart';
import 'core/services/notification_service.dart' show notificationContainer, scheduleWordOfDay;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefsFuture = SharedPreferences.getInstance();
  final dbFuture    = openDatabase(); // native splash covers this

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

  runApp(UncontrolledProviderScope(
    container: container,
    child: const SinosphereApp(),
  ));

  // Wait for activity to fully attach before requesting notification permission.
  // addPostFrameCallback alone is not enough in release builds — onAttachedToActivity
  // fires asynchronously and mainActivity may still be null on first frame.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    scheduleWordOfDay(container);
  });
}

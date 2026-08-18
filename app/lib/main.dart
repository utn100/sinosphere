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

  // Read prefs — fast (~5ms)
  final prefs = await SharedPreferences.getInstance();
  final storedLang  = prefs.getString('sinosphere_lang_mode');
  final storedTheme = prefs.getString('sinosphere_theme_mode');
  if (storedLang == 'korean')  LangModeNotifier.cached = LangMode.korean;
  if (storedTheme == 'dark')   ThemeModeNotifier.cached = ThemeMode.dark;
  if (storedTheme == 'light')  ThemeModeNotifier.cached = ThemeMode.light;
  if (storedTheme == 'system') ThemeModeNotifier.cached = ThemeMode.system;

  // Show loading screen immediately — native splash transitions to Flutter frame
  runApp(const _LoadingApp());

  // DB copy (slow on first install) runs after first frame is visible
  final db = await openDatabase();

  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  notificationContainer = container;

  // Notifications initialise + schedule in background — never block the UI
  initAndSchedule(container);

  // Replace loading screen with real app
  runApp(UncontrolledProviderScope(
    container: container,
    child: const SinosphereApp(),
  ));
}

/// Shown while DB is loading — matches splashscreen colors
class _LoadingApp extends StatelessWidget {
  const _LoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: SizedBox.expand(),
      ),
    );
  }
}

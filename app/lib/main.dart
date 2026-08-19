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

  // Read prefs — fast
  final prefs = await SharedPreferences.getInstance();
  final storedLang  = prefs.getString('sinosphere_lang_mode');
  final storedTheme = prefs.getString('sinosphere_theme_mode');
  if (storedLang == 'korean')  LangModeNotifier.cached = LangMode.korean;
  if (storedTheme == 'dark')   ThemeModeNotifier.cached = ThemeMode.dark;
  if (storedTheme == 'light')  ThemeModeNotifier.cached = ThemeMode.light;
  if (storedTheme == 'system') ThemeModeNotifier.cached = ThemeMode.system;

  // Show loading screen immediately so native splash transitions fast
  runApp(const _LoadingApp());

  // DB copy runs after first frame
  final db = await openDatabase();

  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  notificationContainer = container;

  // Init notifications synchronously so plugin is ready — fast (~10ms, no timezone loop)
  await initNotifications();

  // Replace loading screen with real app
  runApp(UncontrolledProviderScope(
    container: container,
    child: const SinosphereApp(),
  ));

  // Schedule after runApp — activity is active at this point
  scheduleWordOfDay(container);
}

/// Dark loading screen shown while DB copies on first install
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

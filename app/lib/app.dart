import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';

const _kThemeModeKey = 'sinosphere_theme_mode';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static ThemeMode cached = ThemeMode.light;

  @override
  ThemeMode build() => cached;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemeModeKey);
    if (stored == 'dark')   { cached = ThemeMode.dark;   state = ThemeMode.dark;   }
    if (stored == 'light')  { cached = ThemeMode.light;  state = ThemeMode.light;  }
    if (stored == 'system') { cached = ThemeMode.system; state = ThemeMode.system; }
  }

  Future<void> set(ThemeMode m) async {
    cached = m;
    state  = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, m.name);
  }

  void toggle() => set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class SinosphereApp extends ConsumerWidget {
  const SinosphereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Sinosphere Rosetta',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}

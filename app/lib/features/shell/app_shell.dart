import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../app.dart' show themeModeProvider;
import '../../core/services/lang_mode_provider.dart';
import '../../core/theme/app_theme.dart';
import '../dict_card/dict_card_screen.dart';
import '../collections/collections_screen.dart';
import '../graph/graph_screen.dart';
import '../reader/reader_screen.dart';
import '../settings/settings_screen.dart';

class TabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int i) => state = i;
}

final tabIndexProvider = NotifierProvider<TabIndexNotifier, int>(TabIndexNotifier.new);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Request notification permission after first frame — ensures dialog shows while app is visible
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(tabIndexProvider);
    final langMode = ref.watch(langModeProvider);
    final isKorean = langMode == LangMode.korean;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'SINOSPHERE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
            color: isKorean ? const Color(0xFF818CF8) : AppTheme.coral,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune,
                color: isKorean ? const Color(0xFF818CF8) : AppTheme.coral,
                size: 20),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            padding: const EdgeInsets.only(right: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _LangModePill(langMode: langMode),
          ),
        ],
      ),
      body: IndexedStack(
        index: tabIndex,
        children: const [
          DictCardScreen(),
          GraphScreen(),
          ReaderScreen(),
          CollectionsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) => ref.read(tabIndexProvider.notifier).set(i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Dict'),
          NavigationDestination(icon: Icon(Icons.hub_outlined),       selectedIcon: Icon(Icons.hub),       label: 'Graph'),
          NavigationDestination(icon: Icon(Icons.article_outlined),   selectedIcon: Icon(Icons.article),   label: 'Reader'),
          NavigationDestination(icon: Icon(Icons.layers_outlined),    selectedIcon: Icon(Icons.layers),    label: 'Decks'),
        ],
      ),
    );
  }
}

class _LangModePill extends ConsumerWidget {
  final LangMode langMode;
  const _LangModePill({required this.langMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isKorean = langMode == LangMode.korean;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillButton(
            label: 'ZH',
            active: !isKorean,
            activeColor: AppTheme.coral,
            onTap: () => ref.read(langModeProvider.notifier).set(LangMode.chinese),
          ),
          _PillButton(
            label: 'KR',
            active: isKorean,
            activeColor: const Color(0xFF818CF8),
            onTap: () => ref.read(langModeProvider.notifier).set(LangMode.korean),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
            color: active ? activeColor : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

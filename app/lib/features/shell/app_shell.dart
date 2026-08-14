import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dict_card/dict_card_screen.dart';
import '../collections/collections_screen.dart';
import '../graph/graph_screen.dart';
import '../reader/reader_screen.dart';

class TabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int i) => state = i;
}

final tabIndexProvider = NotifierProvider<TabIndexNotifier, int>(TabIndexNotifier.new);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(tabIndexProvider);
    return Scaffold(
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

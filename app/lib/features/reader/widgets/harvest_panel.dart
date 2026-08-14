import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_provider.dart';
import '../../../features/collections/collections_screen.dart' show userCollectionsProvider;
import '../models/token.dart';
import '../reader_provider.dart';

class HarvestPanel extends ConsumerWidget {
  const HarvestPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c     = context.colors;
    final state = ref.watch(readerProvider);

    // Deduplicated CJK tokens ordered by HV resonance (high first)
    final seen  = <String>{};
    final items = state.tokens
        .where((t) => t.isCjk && t.isKnown)
        .where((t) => seen.add(t.text))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: c.border, width: 0.5)),
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Text('VOCABULARY HARVEST',
                style: TextStyle(color: c.textMuted, fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 1)),
            const Spacer(),
            Text('${items.length} words',
                style: TextStyle(color: c.textMuted, fontSize: 11)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => ref.read(readerProvider.notifier).toggleHarvest(),
              child: Icon(Icons.close, color: c.textMuted, size: 18),
            ),
          ]),
        ),

        // Add starred button
        if (state.starred.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.hanviet,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                label: Text('Add ${state.starred.length} starred → Bookmarks',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                onPressed: () => ref.read(readerProvider.notifier).addStarredToBookmarks(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.semantic),
                  foregroundColor: AppTheme.semantic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                label: Text('Create new deck (${state.starred.length} words)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                onPressed: () => _createNewDeck(context, ref, state),
              ),
            ),
          ),
        ],

        // Word list
        Flexible(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(height: 0.5, thickness: 0.5, color: c.border),
            itemBuilder: (_, i) {
              final t   = items[i];
              final id  = t.charId ?? t.wordId ?? t.text;
              final starred = state.starred.contains(id);
              return _HarvestRow(
                token: t, starred: starred,
                onStar: () => ref.read(readerProvider.notifier).toggleStar(id),
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _createNewDeck(
      BuildContext context, WidgetRef ref, ReaderState state) async {
    final db = ref.read(databaseProvider);
    final collections = await db.collectionDao.getAllCollections();
    // Filter out the bookmarks collection
    final userCollections = collections
        .where((c) => c.id != 'bookmarks')
        .toList();

    if (!context.mounted) return;

    // Show deck picker: existing decks + create new option
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _DeckPickerSheet(
        existingDecks: userCollections.map((c) => (id: c.id, name: c.name)).toList(),
      ),
    );

    if (result == null) return; // dismissed

    String deckId;
    if (result == '__new__') {
      // Create new deck
      if (!context.mounted) return;
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('New Deck'),
            content: TextField(controller: ctrl, autofocus: true,
                decoration: const InputDecoration(hintText: 'Deck name')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  child: const Text('Create')),
            ],
          );
        },
      );
      if (name == null || name.isEmpty) return;
      deckId = const Uuid().v4();
      await db.collectionDao.createCollection(deckId, name);
    } else {
      deckId = result;
    }

    // Add all starred words to the deck using same ID resolution as _HarvestRow
    int added = 0;
    final seenIds = <String>{};
    for (final token in ref.read(readerProvider).tokens) {
      if (!token.isCjk || !token.isKnown) continue;
      final id    = token.charId ?? token.wordId ?? token.text;
      final addId = token.charId ?? token.wordId;
      if (addId == null) continue;
      if (!state.starred.contains(id)) continue;
      if (seenIds.contains(addId)) continue;
      seenIds.add(addId);
      await db.collectionDao.addToCollection(deckId, addId);
      added++;
    }

    // Invalidate so Decks tab refreshes
    ref.invalidate(userCollectionsProvider);
    ref.read(readerProvider.notifier).toggleHarvest();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $added words to deck')),
      );
    }
  }
}

class _DeckPickerSheet extends StatelessWidget {
  final List<({String id, String name})> existingDecks;
  const _DeckPickerSheet({required this.existingDecks});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Save to Deck',
              style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        if (existingDecks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('EXISTING DECKS',
                style: TextStyle(color: c.textMuted, fontSize: 9,
                    fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
          const SizedBox(height: 6),
          ...existingDecks.map((deck) => ListTile(
            leading: const Icon(Icons.layers_outlined, color: AppTheme.hanviet),
            title: Text(deck.name, style: TextStyle(color: c.text, fontSize: 14)),
            onTap: () => Navigator.pop(context, deck.id),
          )),
          Divider(color: c.border, height: 8),
        ],
        ListTile(
          leading: const Icon(Icons.create_new_folder_outlined, color: AppTheme.semantic),
          title: const Text('Create new deck…',
              style: TextStyle(color: AppTheme.semantic, fontWeight: FontWeight.w600)),
          onTap: () => Navigator.pop(context, '__new__'),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _HarvestRow extends StatelessWidget {
  final Token token;
  final bool starred;
  final VoidCallback onStar;
  const _HarvestRow({required this.token, required this.starred, required this.onStar});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        // Resonance dot placeholder (amber for known, muted for unknown)
        Container(width: 6, height: 6,
            decoration: BoxDecoration(
                color: token.hanViet.isNotEmpty ? AppTheme.hanviet : c.textMuted,
                shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(token.text,
            style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(token.hanViet,
              style: const TextStyle(color: AppTheme.hanviet, fontSize: 12,
                  fontWeight: FontWeight.w800)),
          Text(
            token.englishDef.length > 40
                ? '${token.englishDef.substring(0, 40)}…'
                : token.englishDef,
            style: TextStyle(color: c.textSub, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ])),
        GestureDetector(
          onTap: onStar,
          child: Icon(
            starred ? Icons.star : Icons.star_border,
            color: starred ? AppTheme.hanviet : c.textMuted,
            size: 20,
          ),
        ),
      ]),
    );
  }
}

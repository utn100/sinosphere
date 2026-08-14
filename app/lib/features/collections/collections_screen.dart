import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/database_provider.dart';
import '../../core/database/database.dart';
import 'collection_detail_screen.dart';

// Seeded HSK decks
const _hskDecks = [
  (level: 1, count: 470,  color: Color(0xFF10B981), desc: 'Core basics'),
  (level: 2, count: 737,  color: Color(0xFF3B82F6), desc: 'Everyday use'),
  (level: 3, count: 953,  color: Color(0xFF8B5CF6), desc: 'Conversational'),
  (level: 4, count: 982,  color: Color(0xFFF59E0B), desc: 'Upper intermediate'),
  (level: 5, count: 1065, color: Color(0xFFEF4444), desc: 'Advanced'),
  (level: 6, count: 1131, color: Color(0xFFEC4899), desc: 'Mastery'),
  (level: 7, count: 5619, color: Color(0xFF06B6D4), desc: 'HSK 7-9 · Professional'),
];

// Seeded topic packs
const _topicPacks = [
  (name: 'Nature & Cosmos',     icon: '🌿', topicId: 'nature',   resonance: 'high'),
  (name: 'Body & Mind',         icon: '🫀', topicId: 'body',     resonance: 'high'),
  (name: 'City & Places',       icon: '🏙️', topicId: 'city',     resonance: 'high'),
  (name: 'Emotions & Character',icon: '💭', topicId: 'emotions', resonance: 'high'),
  (name: 'Time & History',      icon: '⏳', topicId: 'time',     resonance: 'high'),
  (name: 'Family & Society',    icon: '👨‍👩‍👧', topicId: 'family',   resonance: 'high'),
  (name: 'Learning & Knowledge',icon: '📚', topicId: 'learning', resonance: 'high'),
  (name: 'Travel & Transport',  icon: '✈️', topicId: 'travel',   resonance: 'medium'),
  (name: 'Food & Drink',        icon: '🍜', topicId: 'food',     resonance: 'medium'),
  (name: 'Business & Economy',  icon: '💼', topicId: 'business', resonance: 'high'),
  (name: 'Strong HV Cognates',  icon: '🔤', topicId: 'cognates', resonance: 'high'),
  (name: 'Popular Song Vocab',  icon: '🎵', topicId: 'songs',    resonance: 'medium'),
];

final userCollectionsProvider = FutureProvider<List<UserCollection>>(
  (ref) => ref.read(databaseProvider).collectionDao.getAllCollections(),
);

// Public so dict_card can invalidate it after bookmarking
final bookmarkedSymbolsProvider = FutureProvider<List<String>>(
  (ref) => ref.read(databaseProvider).collectionDao.getBookmarkedSymbols(),
);

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text('Decks & Collections',
                    style: TextStyle(
                        color: c.text, fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ),
            ),

            // HSK Level grid
            SliverToBoxAdapter(child: _sectionHeader(c, 'HSK Levels',
                subtitle: '10,957 words total')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _HskCard(
                    deck: _hskDecks[i],
                    onTap: () => Navigator.push(ctx, MaterialPageRoute(
                        builder: (_) => HskDetailScreen(hskLevel: _hskDecks[i].level))),
                  ),
                  childCount: _hskDecks.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.1,
                ),
              ),
            ),

            // Topic packs
            SliverToBoxAdapter(child: _sectionHeader(c, 'Topic Collections',
                subtitle: 'Curated by Hán-Việt resonance')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _TopicRow(
                    pack: _topicPacks[i],
                    onTap: () => Navigator.push(ctx, MaterialPageRoute(
                        builder: (_) => TopicDetailScreen(
                            topicId: _topicPacks[i].topicId,
                            topicName: _topicPacks[i].name))),
                  ),
                  childCount: _topicPacks.length,
                ),
              ),
            ),

            // User collections
            SliverToBoxAdapter(
              child: _sectionHeader(c, 'My Collections', trailing:
                TextButton.icon(
                  onPressed: () => _createCollection(context, ref),
                  icon: const Icon(Icons.add, size: 16,
                      color: AppTheme.hanviet),
                  label: const Text('New',
                      style: TextStyle(
                          color: AppTheme.hanviet,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            _UserCollectionsList(),

            // Bookmarks
            SliverToBoxAdapter(child: _sectionHeader(c,
                'Recently Bookmarked')),
            _BookmarksGrid(),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(dynamic c, String title,
      {String? subtitle, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: c.textMuted, fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(
                          color: c.textMuted, fontSize: 10)),
              ],
            ),
          ),
          // ignore: use_null_aware_elements
          if (trailing case final t?) t,
        ],
      ),
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('New Collection'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Collection name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    if (name != null && name.isNotEmpty) {
      final id = const Uuid().v4();
      await ref.read(databaseProvider).collectionDao.createCollection(id, name);
      ref.invalidate(userCollectionsProvider);
    }
  }
}

class _HskCard extends StatelessWidget {
  final ({int level, int count, Color color, String desc}) deck;
  final VoidCallback? onTap;
  const _HskCard({required this.deck, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: deck.color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: deck.color.withAlpha(64), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('HSK ${deck.level}',
              style: TextStyle(
                  color: deck.color, fontSize: 11,
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
          Text('${deck.count}',
              style: TextStyle(
                  color: c.text, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(deck.desc,
              style: TextStyle(color: c.textMuted, fontSize: 9),
              textAlign: TextAlign.center),
        ],
      ),
    ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final ({String name, String icon, String topicId, String resonance}) pack;
  final VoidCallback? onTap;
  const _TopicRow({required this.pack, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        children: [
          Text(pack.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(pack.name,
                style: TextStyle(
                    color: c.text, fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Row(
            children: [
              Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                      color: pack.resonance == 'high'
                          ? AppTheme.hanviet
                          : const Color(0xFF38BDF8),
                      shape: BoxShape.circle)),
              const SizedBox(width: 3),
              Text(pack.resonance == 'high' ? 'Strong HV' : 'Mixed HV',
                  style: TextStyle(color: c.textMuted, fontSize: 9)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: c.textMuted, size: 16),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _UserCollectionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(userCollectionsProvider);
    final c = context.colors;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: collections.when(
        loading: () => const SliverToBoxAdapter(
            child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        data: (list) {
          final user = list.where((col) =>
              col.id != bookmarksCollectionId).toList();
          if (user.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No custom collections yet.',
                    style: TextStyle(
                        color: c.textMuted, fontSize: 13,
                        fontStyle: FontStyle.italic)),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final col = user[i];
                return GestureDetector(
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => CollectionDetailScreen(
                          collectionId: col.id, collectionName: col.name))),
                  child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.learned.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.learned.withAlpha(51),
                        width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Text(col.icon ?? '📂',
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(col.name,
                            style: TextStyle(
                                color: c.text, fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.textMuted, size: 18),
                        onPressed: () async {
                          await ref
                              .read(databaseProvider)
                              .collectionDao
                              .deleteCollection(col.id);
                          ref.invalidate(userCollectionsProvider);
                        },
                      ),
                    ],
                  ),
                  ),  // Container
                );   // GestureDetector
              },
              childCount: user.length,
            ),
          );
        },
      ),
    );
  }
}

class _BookmarksGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbols = ref.watch(bookmarkedSymbolsProvider);
    final c = context.colors;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: symbols.when(
        loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
        error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        data: (list) {
          if (list.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No bookmarks yet.',
                    style: TextStyle(
                        color: c.textMuted, fontSize: 13,
                        fontStyle: FontStyle.italic)),
              ),
            );
          }
          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Container(
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border, width: 0.5),
                ),
                child: Center(
                  child: Text(list[i],
                      style: TextStyle(
                          color: c.text, fontSize: 24,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              childCount: list.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
          );
        },
      ),
    );
  }
}

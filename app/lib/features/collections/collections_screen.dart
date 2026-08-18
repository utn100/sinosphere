import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/database_provider.dart';
import '../../core/services/lang_mode_provider.dart';
import '../../core/database/database.dart';
import '../practice/daily_practice_screen.dart';
import 'collection_detail_screen.dart';

// Seeded HSK decks
const _hskDecks = [
  (level: 1, count: 470,  color: Color(0xFF10B981), desc: 'Core basics'),
  (level: 2, count: 737,  color: Color(0xFF3B82F6), desc: 'Everyday use'),
  (level: 3, count: 953,  color: Color(0xFF8B5CF6), desc: 'Conversational'),
  (level: 4, count: 982,  color: Color(0xFFF59E0B), desc: 'Upper intermediate'),
  (level: 5, count: 1065, color: Color(0xFFEF4444), desc: 'Advanced'),
  (level: 6, count: 1131, color: Color(0xFFEC4899), desc: 'Mastery'),
  (level: 7, count: 5619, color: Color(0xFF06B6D4), desc: 'Professional'),
];

// Seeded TOPIK decks (proxy levels from HSK mapping)
// TOPIK bands: A=Beginner(T1), B=Intermediate(T3), C=Advanced(T5+T6)
// Sino-Korean (compound_words topik_in_source=1, len>=2) + native (korean_words)
const _topikDecks = [
  (level: 1, band: 'A', levels: [1],    count: 924,  color: Color(0xFF6366F1), desc: 'Beginner'),
  (level: 3, band: 'B', levels: [3],    count: 2382, color: Color(0xFF3B82F6), desc: 'Intermediate'),
  (level: 5, band: 'C', levels: [5, 6], count: 3118, color: Color(0xFF8B5CF6), desc: 'Advanced'),
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

// Public so dict_card and compound_list can invalidate it after bookmarking
final bookmarkedSymbolsProvider = FutureProvider<List<String>>(
  (ref) => ref.read(databaseProvider).collectionDao.getBookmarkedSymbols(),
);

// Full bookmark items (characters + compounds) — used by the bookmarks grid
final bookmarkedItemsProvider = FutureProvider<List<CollectionItem>>(
  (ref) => ref.read(databaseProvider).collectionDao.getBookmarkedItems(),
);

final topicWordCountProvider =
    FutureProvider.family<int, ({String topicId, bool krOnly})>(
  (ref, args) => ref
      .read(databaseProvider)
      .collectionDao
      .getTopicWordCount(args.topicId, krOnly: args.krOnly),
);

final hskWordCountProvider = FutureProvider.family<int, int>(
  (ref, level) =>
      ref.read(databaseProvider).collectionDao.getHskWordCount(level),
);

final hskMemorizedCountProvider = FutureProvider.family<int, int>(
  (ref, level) =>
      ref.read(databaseProvider).collectionDao.getMemorizedCountByHsk(level),
);

final topikMemorizedCountProvider =
    FutureProvider.family<int, String>(
  (ref, levelsKey) {
    final levels = levelsKey.split(',').map(int.parse).toList();
    return ref.read(databaseProvider).collectionDao.getMemorizedCountByTopik(levels);
  },
);

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c        = context.colors;
    final langMode = ref.watch(langModeProvider);
    final isKorean = langMode == LangMode.korean;

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

            // Daily Practice banner
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DailyPracticeScreen())),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [
                        AppTheme.hanviet.withAlpha(40),
                        const Color(0xFF818CF8).withAlpha(30),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.hanviet.withAlpha(80), width: 0.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.hanviet.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_outlined, color: AppTheme.hanviet, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Daily Practice',
                          style: TextStyle(color: AppTheme.hanviet, fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      Text('Practice writing 10 random words',
                          style: TextStyle(color: c.textMuted, fontSize: 12)),
                    ])),
                    Icon(Icons.chevron_right, color: c.textMuted, size: 20),
                  ]),
                ),
              ),
            ),

            if (isKorean) ...[
              // TOPIK Level grid
              SliverToBoxAdapter(child: _sectionHeader(c, 'TOPIK Levels',
                  subtitle: '${_topikDecks.fold(0, (s, d) => s + d.count).toString()} words total')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _TopikCard(
                      deck: _topikDecks[i],
                      onTap: () => Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => TopikDetailScreen(
                              topikLevels: _topikDecks[i].levels,
                              band: _topikDecks[i].band,
                              desc: _topikDecks[i].desc))),
                    ),
                    childCount: _topikDecks.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.1,
                  ),
                ),
              ),
            ] else ...[
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
            ],

            // Topic packs
            SliverToBoxAdapter(child: _sectionHeader(c, 'Topic Collections',
                subtitle: isKorean ? '% Sino-Korean' : 'Curated by Hán-Việt resonance')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _TopicRow(
                    pack: _topicPacks[i],
                    isKorean: isKorean,
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
                  icon: const Icon(Icons.add, size: 16, color: AppTheme.hanviet),
                  label: const Text('New',
                      style: TextStyle(color: AppTheme.hanviet, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            _UserCollectionsList(),

            // Bookmarks
            SliverToBoxAdapter(child: _sectionHeader(c, 'Recently Bookmarked')),
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

class _HskCard extends ConsumerWidget {
  final ({int level, int count, Color color, String desc}) deck;
  final VoidCallback? onTap;
  const _HskCard({required this.deck, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final countAsync = ref.watch(hskWordCountProvider(deck.level));
    final count = countAsync.maybeWhen(data: (n) => n, orElse: () => deck.count);
    final memAsync = ref.watch(hskMemorizedCountProvider(deck.level));
    final mem = memAsync.maybeWhen(data: (n) => n, orElse: () => 0);
    final pct = count > 0 ? mem / count : 0.0;
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
          Text('HSK ${deck.level == 7 ? '7-9' : deck.level}',
              style: TextStyle(
                  color: deck.color, fontSize: 11,
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
          Text('$count',
              style: TextStyle(
                  color: c.text, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(deck.desc,
              style: TextStyle(color: c.textMuted, fontSize: 9),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 3,
                backgroundColor: deck.color.withAlpha(30),
                color: deck.color,
              ),
            ),
          ),
          Text('${(pct * 100).round()}%',
              style: TextStyle(color: deck.color, fontSize: 8,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    ),
    );
  }
}

class _TopikCard extends ConsumerWidget {
  final ({int level, List<int> levels, String band, int count, Color color, String desc}) deck;
  final VoidCallback? onTap;
  const _TopikCard({required this.deck, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final memAsync = ref.watch(topikMemorizedCountProvider(deck.levels.join(',')));
    final mem = memAsync.maybeWhen(data: (n) => n, orElse: () => 0);
    final total = deck.count;
    final pct = total > 0 ? mem / total : 0.0;
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
          Text('TOPIK ${deck.band}',
              style: TextStyle(color: deck.color, fontSize: 11,
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
          Text('${deck.count}',
              style: TextStyle(color: c.text, fontSize: 22,
                  fontWeight: FontWeight.w900)),
          Text(deck.desc,
              style: TextStyle(color: c.textMuted, fontSize: 9),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 3,
                backgroundColor: deck.color.withAlpha(30),
                color: deck.color,
              ),
            ),
          ),
          Text('${(pct * 100).round()}%',
              style: TextStyle(color: deck.color, fontSize: 8,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    ),  // GestureDetector
    );
  }
}class _TopicRow extends ConsumerWidget {
  final ({String name, String icon, String topicId, String resonance}) pack;
  final VoidCallback? onTap;
  final bool isKorean;
  const _TopicRow({required this.pack, this.onTap, this.isKorean = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final countAsync = ref.watch(
        topicWordCountProvider((topicId: pack.topicId, krOnly: isKorean)));
    final countText = countAsync.maybeWhen(
        data: (n) => '$n words', orElse: () => '…');
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.name,
                    style: TextStyle(
                        color: c.text, fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(countText,
                    style: TextStyle(color: c.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                      color: isKorean
                          ? const Color(0xFF818CF8)
                          : (pack.resonance == 'high'
                              ? AppTheme.hanviet
                              : const Color(0xFF38BDF8)),
                      shape: BoxShape.circle)),
              const SizedBox(width: 3),
              Text(
                isKorean
                    ? (pack.resonance == 'high' ? '~85% SK' : '~50% SK')
                    : (pack.resonance == 'high' ? 'Strong HV' : 'Mixed HV'),
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
    final items = ref.watch(bookmarkedItemsProvider);
    final c = context.colors;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: items.when(
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
              (ctx, i) {
                final item = list[i];
                final isKorean = ref.read(langModeProvider) == LangMode.korean;
                final shown = (isKorean && item.hangul != null) ? item.hangul! : item.display;
                return GestureDetector(
                  onTap: () => showCollectionWordSheet(ctx, ref,
                    display:    shown,
                    hanViet:    item.hanViet,
                    pinyin:     item.pinyin,
                    englishDef: item.englishDef,
                    wordId:     item.isChar ? null : item.id,
                    hangul:     item.hangul,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border, width: 0.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(shown,
                            style: TextStyle(
                                color: c.text,
                                fontSize: shown.length == 1 ? 22 : 14,
                                fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(item.hanViet,
                            style: const TextStyle(
                                color: AppTheme.hanviet, fontSize: 8,
                                fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
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

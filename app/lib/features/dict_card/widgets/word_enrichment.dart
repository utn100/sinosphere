import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/database/database.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/database_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../dict_card_provider.dart' show activeSymbolProvider;
import '../../shell/app_shell.dart' show tabIndexProvider;
import 'bookmark_button.dart';

// ── Clipboard helper ─────────────────────────────────────────────────────────

void copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));

  // Show an overlay toast that sits above modal bottom sheets.
  // SnackBar via ScaffoldMessenger is always rendered below the sheet overlay.
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _CopyToast(
    text: text,
    onDone: () => entry.remove(),
  ));
  overlay.insert(entry);
}

class _CopyToast extends StatefulWidget {
  final String text;
  final VoidCallback onDone;
  const _CopyToast({required this.text, required this.onDone});

  @override
  State<_CopyToast> createState() => _CopyToastState();
}

class _CopyToastState extends State<_CopyToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), () async {
      if (mounted) {
        await _ctrl.reverse();
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155), width: 0.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(100),
                    blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline,
                  color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 8),
              Flexible(child: Text(
                '"${widget.text}" copied to clipboard',
                style: const TextStyle(
                    color: Color(0xFFF1F5F9), fontSize: 13),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Loads a compound word by simplified Chinese — used to enrich synonym/antonym chips.
final synonymLookupProvider = FutureProvider.family<CompoundWord?, String>(
  (ref, simplified) =>
      ref.read(databaseProvider).compoundDao.getBySimplified(simplified),
);

/// Loads + generates word enrichment (synonyms / antonyms / examples).
final wordEnrichmentProvider =
    FutureProvider.family<CompoundWord?, String>((ref, wordId) async {
  final db = ref.read(databaseProvider);
  final word = await db.compoundDao.getById(wordId);
  if (word == null) return null;

  // Already enriched — return as-is
  if (word.synonyms != null ||
      word.antonyms != null ||
      word.exampleSentence != null) {
    return word;
  }

  // Try AI generation
  final settings = await ref.read(llmSettingsProvider.future);
  if (!settings.isConfigured) return word;

  final ai = ref.read(aiServiceProvider);
  final details = await ai.generateWordDetails(
      word.simplified, word.pinyin, word.englishDef, settings);
  if (details == null) return word;

  final syns = details.synonyms.isNotEmpty ? details.synonyms.join(',') : null;
  final ants = details.antonyms.isNotEmpty ? details.antonyms.join(',') : null;
  final exJson = details.examples.isNotEmpty
      ? jsonEncode(details.examples
          .map((e) => {'zh': e.zh, 'py': e.py, 'en': e.en})
          .toList())
      : null;

  await db.compoundDao.updateWordDetails(wordId,
      synonyms: syns, antonyms: ants, exampleSentence: exJson);

  return word.copyWith(
    synonyms:        Value(syns),
    antonyms:        Value(ants),
    exampleSentence: Value(exJson),
  );
});

// ── Public widget ─────────────────────────────────────────────────────────────

class WordEnrichmentSection extends ConsumerWidget {
  final String wordId;
  final String simplified;
  final String pinyin;
  final String englishDef;

  final String? initialSynonyms;
  final String? initialAntonyms;
  final String? initialExample;

  const WordEnrichmentSection({
    super.key,
    required this.wordId,
    required this.simplified,
    required this.pinyin,
    required this.englishDef,
    this.initialSynonyms,
    this.initialAntonyms,
    this.initialExample,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasInitial = initialSynonyms != null ||
        initialAntonyms != null ||
        initialExample != null;

    if (hasInitial) {
      return _EnrichmentContent(
        synonyms: initialSynonyms,
        antonyms: initialAntonyms,
        example:  initialExample,
      );
    }

    final async = ref.watch(wordEnrichmentProvider(wordId));
    return async.when(
      loading: () => _EnrichmentShimmer(),
      error:   (_, e) => const SizedBox.shrink(),
      data: (word) {
        if (word == null) return const SizedBox.shrink();
        return _EnrichmentContent(
          synonyms: word.synonyms,
          antonyms: word.antonyms,
          example:  word.exampleSentence,
        );
      },
    );
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────────

class _EnrichmentShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(height: 14, width: 180, color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8)),
          Container(height: 14, width: 140, color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8)),
          Container(height: 14, width: 220, color: Colors.white),
        ],
      ),
    );
  }
}

/// Parses `example_sentence` — JSON array or legacy plain string.
List<({String zh, String py, String en})> _parseExamples(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final list = jsonDecode(raw) as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return (
        zh: m['zh'] as String? ?? '',
        py: m['py'] as String? ?? '',
        en: m['en'] as String? ?? '',
      );
    }).toList();
  } catch (_) {
    // Legacy plain-text row — show as-is with no pinyin/English
    return [(zh: raw, py: '', en: '')];
  }
}

class _EnrichmentContent extends StatelessWidget {
  final String? synonyms;
  final String? antonyms;
  final String? example;

  const _EnrichmentContent({this.synonyms, this.antonyms, this.example});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final synList = synonyms?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
    final antList = antonyms?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
    final examples = _parseExamples(example);

    if (synList.isEmpty && antList.isEmpty && examples.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Divider(color: c.border, height: 1),
        const SizedBox(height: 10),

        if (synList.isNotEmpty) ...[
          _LabelRow(label: 'Synonyms', labelColor: AppTheme.hanviet),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: synList
                .map((w) => _SynChip(simplified: w, color: AppTheme.hanviet))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],

        if (antList.isNotEmpty) ...[
          _LabelRow(label: 'Antonyms', labelColor: AppTheme.sky),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: antList
                .map((w) => _SynChip(simplified: w, color: AppTheme.sky))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],

        if (examples.isNotEmpty) ...[
          _LabelRow(label: 'Examples', labelColor: c.textSub),
          const SizedBox(height: 6),
          ...examples.asMap().entries.map((entry) {
            final ex = entry.value;
            return GestureDetector(
              onLongPress: () => copyToClipboard(context, ex.zh),
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: entry.key < examples.length - 1 ? 10 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.zh,
                        style: TextStyle(
                            color: c.text, fontSize: 14, height: 1.5)),
                    if (ex.py.isNotEmpty)
                      Text(ex.py,
                          style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 12, height: 1.4)),
                    if (ex.en.isNotEmpty)
                      Text(ex.en,
                          style: TextStyle(
                              color: c.textMuted,
                              fontSize: 12, height: 1.4,
                              fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final Color labelColor;
  const _LabelRow({required this.label, required this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            color: labelColor, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 0.5));
  }
}

/// Synonym/antonym chip — looks up the word in compound_words to show pinyin.
class _SynChip extends ConsumerWidget {
  final String simplified;
  final Color color;
  const _SynChip({required this.simplified, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(synonymLookupProvider(simplified));
    final pinyin = async.maybeWhen(
        data: (w) => w?.pinyin ?? '', orElse: () => '');

    return GestureDetector(
      onTap: () => _onTap(context, ref, async.value),
      onLongPress: () => copyToClipboard(context, simplified),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(128), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(simplified,
                style: TextStyle(
                    color: color, fontSize: 15,
                    fontWeight: FontWeight.w700)),
            if (pinyin.isNotEmpty)
              Text(pinyin,
                  style: TextStyle(
                      color: color.withAlpha(180),
                      fontSize: 10, height: 1.3)),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, CompoundWord? word) {
    if (word == null) return;
    // Open a mini word sheet for this synonym/antonym
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.4, minChildSize: 0.3, maxChildSize: 0.85,
        expand: false,
        builder: (_, ctrl) => _SynWordSheet(word: word, scrollController: ctrl),
      ),
    );
  }
}

/// Compact word sheet for a synonym/antonym — no enrichment to avoid infinite recursion.
class _SynWordSheet extends ConsumerWidget {
  final CompoundWord word;
  final ScrollController scrollController;
  const _SynWordSheet({required this.word, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final chars = word.simplified.split('');
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: c.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        // Tappable character chips
        Wrap(
          spacing: 4, runSpacing: 4,
          children: chars.map((ch) => GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              ref.read(activeSymbolProvider.notifier).set(ch);
              ref.read(tabIndexProvider.notifier).set(0);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Text(ch, style: TextStyle(
                  color: c.text, fontSize: 48,
                  fontWeight: FontWeight.w700, height: 1.1)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
          Text(word.hanViet,
              style: const TextStyle(color: AppTheme.hanviet,
                  fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          Text(word.pinyin,
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        Text(word.englishDef,
            style: TextStyle(color: c.text, fontSize: 14, height: 1.5)),
        if (word.hskLevel != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: AppTheme.hanviet.withAlpha(38),
                borderRadius: BorderRadius.circular(8)),
            child: Text('HSK ${word.hskLevel}',
                style: const TextStyle(color: AppTheme.hanviet,
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
        const SizedBox(height: 10),
        BookmarkButton(wordId: word.id),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.surf, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Row(children: [
            Icon(Icons.touch_app_outlined, size: 14, color: c.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Tap any character above to open its dictionary card',
              style: TextStyle(color: c.textMuted, fontSize: 11),
            )),
          ]),
        ),
      ],
    );
  }
}

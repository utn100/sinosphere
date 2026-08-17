import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/services/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../search/search_bar.dart';
import 'graph_provider.dart';
import 'widgets/pivot_browser.dart';

class KoreanGraphView extends ConsumerStatefulWidget {
  const KoreanGraphView({super.key});

  @override
  ConsumerState<KoreanGraphView> createState() => _KoreanGraphViewState();
}

class _KoreanGraphViewState extends ConsumerState<KoreanGraphView> {
  List<KrPivot> _dynamicPivots = [];
  bool   _isNativeWord = false;
  double _focusLens    = 65;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final saved = ref.read(koreanGraphSearchProvider);
      if (saved != null) _rebuildPivots(saved.simplified, saved.hangul);
    });
  }

  Future<void> _onSearchResult(SearchResult result) async {
    ref.read(koreanGraphSearchProvider.notifier).set(
        (simplified: result.simplified, hangul: result.hangul ?? result.simplified));
    await _rebuildPivots(result.simplified, result.hangul ?? result.simplified);
  }

  Future<void> _rebuildPivots(String simplified, String hangul) async {
    final db    = ref.read(databaseProvider);
    final chars = await db.graphDao.getWordComponents(simplified);
    if (!mounted) return;

    if (chars.isEmpty) {
      setState(() {
        _dynamicPivots   = [];
        _isNativeWord    = true;
      });
      return;
    }

    final pivots = chars.map((c) => (
      hanzi:   c.symbol,
      hangul:  c.hangul ?? c.symbol,
      romaja:  c.hangul ?? '',
      meaning: _shortDef(c.englishDef),
      pinyin:  c.pinyin,
    )).toList();

    setState(() {
      _dynamicPivots   = pivots;
      _isNativeWord    = false;
    });
  }

  void _clearSearch() {
    ref.read(koreanGraphSearchProvider.notifier).set(null);
    setState(() {
      _dynamicPivots = [];
      _isNativeWord  = false;
    });
  }

  String _shortDef(String def) {
    final first = def.split(';').first.split(',').first.trim();
    return first.length > 12 ? '${first.substring(0, 12)}…' : first;
  }

  @override
  Widget build(BuildContext context) {
    final c        = context.colors;
    final saved    = ref.watch(koreanGraphSearchProvider);
    final displayWord = saved?.hangul;

    // React to external provider changes (e.g. from Korean dict card graph teaser)
    ref.listen(koreanGraphSearchProvider, (prev, next) {
      if (next != null && next.simplified != prev?.simplified) {
        _rebuildPivots(next.simplified, next.hangul);
      }
    });

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(children: [
          SinosphereSearchBar(
            placeholder: 'Search: 학교 / 전화 / school...',
            searchOverride: (q) =>
                ref.read(databaseProvider).compoundDao.searchKorean(q),
            onResultSelected: _onSearchResult,
          ),
          if (displayWord != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                Text('Exploring: ', style: TextStyle(color: c.textMuted, fontSize: 11)),
                Text(displayWord,
                    style: const TextStyle(color: Color(0xFF818CF8),
                        fontSize: 11, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: _clearSearch,
                  child: Text('Clear', style: TextStyle(color: c.textMuted, fontSize: 11)),
                ),
              ]),
            ),
          const SizedBox(height: 8),
          _FocusLensBar(value: _focusLens,
              onChanged: (v) => setState(() => _focusLens = v), c: c),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: PivotBrowserView(
          focusLens: _focusLens,
          dynamicPivots: _dynamicPivots.isNotEmpty ? _dynamicPivots : null,
          nativeWordName: _isNativeWord ? (saved?.hangul ?? '') : null,
        ),
      ),
    ]);
  }
}

// ── Focus Lens slider ─────────────────────────────────────────────────────────

class _FocusLensBar extends StatelessWidget {
  final double value;
  final void Function(double) onChanged;
  final dynamic c;
  const _FocusLensBar({required this.value, required this.onChanged, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('ZH', style: TextStyle(color: AppTheme.hanviet,
              fontSize: 10, fontWeight: FontWeight.w700)),
          Text('Focus Lens', style: TextStyle(color: c.textMuted,
              fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const Text('KR', style: TextStyle(color: Color(0xFF818CF8),
              fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Stack(alignment: Alignment.center, children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                AppTheme.hanviet, Color(0xFFF59E0B), Color(0xFF818CF8),
              ]),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF818CF8).withAlpha(40),
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
            ),
            child: Slider(value: value, min: 0, max: 100, onChanged: onChanged),
          ),
        ]),
      ]),
    );
  }
}

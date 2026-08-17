import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/services/database_provider.dart';
import '../../core/services/lang_mode_provider.dart';
import '../../core/theme/app_theme.dart';

const _skyColor = Color(0xFF38BDF8);

// Still needed so other widgets can watch the active search query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// ── Search Bar ────────────────────────────────────────────────────────────────
class SinosphereSearchBar extends ConsumerStatefulWidget {
  final void Function(SearchResult result) onResultSelected;
  final String? placeholder;
  final Future<List<SearchResult>> Function(String query)? searchOverride;

  const SinosphereSearchBar({
    super.key,
    required this.onResultSelected,
    this.placeholder,
    this.searchOverride,
  });

  @override
  ConsumerState<SinosphereSearchBar> createState() => _SinosphereSearchBarState();
}

class _SinosphereSearchBarState extends ConsumerState<SinosphereSearchBar> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();

  Timer? _debounce;
  List<SearchResult> _results   = [];
  bool   _loading               = false;
  String? _error;
  bool   _showResults           = false;
  SearchResult? _lastResult;   // persists as chip after sheet is dismissed

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // M4: clear chip whenever user starts typing a new query
    if (value.trim().isEmpty) {
      setState(() { _showResults = false; _results = []; _loading = false;
          _error = null; _lastResult = null; });
      return;
    }
    setState(() { _showResults = true; _loading = true; _error = null; _lastResult = null; });
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(value.trim()));
  }

  Future<void> _runSearch(String query) async {
    try {
      List<SearchResult> results;

      if (widget.searchOverride != null) {
        results = await widget.searchOverride!(query);
      } else {
        final db = ref.read(databaseProvider);
        results = await db.compoundDao.search(query);

        // H5: if few compound results, also search characters table directly
        if (results.length < 5) {
          final chars = await db.characterDao.searchCharacters(query);
          final existingWords = results.map((r) => r.simplified).toSet();
          for (final c in chars) {
            if (!existingWords.contains(c.symbol)) {
              results = [
                SearchResult(
                  id: '',
                  simplified: c.symbol, pinyin: c.pinyin,
                  hanViet: c.hanViet, englishDef: c.englishDef,
                  hskLevel: null, frequencyRank: null,
                ),
                ...results,
              ];
            }
          }
        }
      }

      if (!mounted) return;
      setState(() { _results = results; _loading = false; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _onSelect(SearchResult item) {
    _debounce?.cancel();
    final langMode = ref.read(langModeProvider);
    _controller.text = (langMode == LangMode.korean && item.hangul != null)
        ? item.hangul!
        : item.simplified;
    setState(() { _showResults = false; _lastResult = item; });
    _focusNode.unfocus();
    widget.onResultSelected(item);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() { _showResults = false; _results = []; _loading = false; _error = null; _lastResult = null; });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onTap: () {
            if (_controller.text.isNotEmpty && _results.isNotEmpty) {
              setState(() => _showResults = true);
            }
          },
          style: TextStyle(color: c.text, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.placeholder ?? 'Search: 晨 / chén / morning / THẦN...',
            prefixIcon: Icon(Icons.search, color: c.textMuted, size: 20),
            suffixIcon: _controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: _clear,
                    child: Icon(Icons.close, color: c.textMuted, size: 18))
                : null,
          ),
        ),
        if (_showResults) _buildDropdown(c),
        if (!_showResults && _lastResult != null) _buildChip(c),
      ],
    );
  }

  Widget _buildChip(dynamic c) {
    final r = _lastResult!;
    final langMode = ref.watch(langModeProvider);
    final isKorean = langMode == LangMode.korean && r.hangul != null;
    final chipColor = isKorean ? const Color(0xFF818CF8) : AppTheme.hanviet;
    final displayWord = isKorean ? r.hangul! : r.simplified;
    final displaySub  = isKorean ? (r.romaja ?? '') : r.hanViet;
    return GestureDetector(
      onTap: () => widget.onResultSelected(r),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: chipColor.withAlpha(77), width: 0.8),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(
                displayWord.length > 2 ? displayWord.substring(0, 2) : displayWord,
                style: TextStyle(color: c.text, fontSize: displayWord.length == 1 ? 16 : 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(displaySub,
                style: TextStyle(color: chipColor, fontSize: 12, fontWeight: FontWeight.w800)),
            Text(
              r.englishDef.length > 35 ? '${r.englishDef.substring(0, 35)}…' : r.englishDef,
              style: TextStyle(color: c.textMuted, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ])),
          Icon(Icons.keyboard_arrow_up_rounded, color: chipColor, size: 18),
        ]),
      ),
    );
  }

  Widget _buildDropdown(dynamic c) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 0.5),
        boxShadow: [BoxShadow(
            color: Colors.black.withAlpha(76), blurRadius: 20,
            offset: const Offset(0, 8))],
      ),
      child: _buildDropdownContent(c),
    );
  }

  Widget _buildDropdownContent(dynamic c) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.hanviet)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $_error', style: TextStyle(color: c.textMuted, fontSize: 12)),
      );
    }
    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No results', style: TextStyle(color: c.textMuted, fontSize: 13)),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, _) => Divider(height: 0.5, thickness: 0.5, color: c.border),
      itemBuilder: (context, i) {
        final item = _results[i];
        final langMode = ref.watch(langModeProvider);
        final isKorean = langMode == LangMode.korean;
        // KR mode: hangul primary in icon box; ZH mode: simplified as before
        final iconText  = isKorean && item.hangul != null
            ? (item.hangul!.length > 2 ? item.hangul!.substring(0, 2) : item.hangul!)
            : (item.simplified.length > 2 ? item.simplified.substring(0, 2) : item.simplified);
        final iconSize  = isKorean
            ? (item.hangul?.length == 1 ? 20.0 : 14.0)
            : (item.simplified.length == 1 ? 20.0 : 14.0);
        // Primary text line
        final primaryText  = isKorean ? (item.hangul ?? item.simplified) : item.pinyin;
        final primaryColor = isKorean ? const Color(0xFF818CF8) : _skyColor;
        // Secondary text line
        final secondaryText  = isKorean ? (item.romaja ?? '') : item.hanViet;
        final secondaryColor = isKorean
            ? const Color(0xFF818CF8).withAlpha(180)
            : AppTheme.hanviet;
        return InkWell(
          onTap: () => _onSelect(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(iconText,
                    style: TextStyle(color: c.text, fontSize: iconSize,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    if (primaryText.isNotEmpty)
                      Flexible(
                        child: Text(primaryText,
                            style: TextStyle(color: primaryColor,
                                fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                    if (secondaryText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(secondaryText,
                            style: TextStyle(color: secondaryColor,
                                fontSize: 13, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    // In KR mode show simplified as small muted hint
                    if (isKorean && item.simplified != (item.hangul ?? item.simplified)) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(item.simplified,
                            style: TextStyle(color: c.textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ]),
                  Text(
                    item.englishDef.length > 50
                        ? '${item.englishDef.substring(0, 50)}…'
                        : item.englishDef,
                    style: TextStyle(color: c.textSub, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
              // Badge: TOPIK in KR mode, HSK in ZH mode
              if (isKorean && item.topikLevel != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF818CF8).withAlpha(38),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('T${item.topikLevel}',
                      style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ] else if (!isKorean && item.hskLevel != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.hanviet.withAlpha(38),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('HSK${item.hskLevel}',
                      style: const TextStyle(color: AppTheme.hanviet, fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }
}

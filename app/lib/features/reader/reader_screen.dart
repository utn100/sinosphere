import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/ai_service.dart';
import '../graph/graph_provider.dart';
import '../settings/settings_screen.dart';
import '../shell/app_shell.dart';
import 'models/token.dart';
import 'reader_provider.dart';
import 'seeded_texts.dart';
import 'widgets/annotated_text.dart';
import 'widgets/token_detail_sheet.dart';
import 'widgets/harvest_panel.dart';
import 'widgets/history_list.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _textCtrl   = TextEditingController();
  final _titleCtrl  = TextEditingController();
  final _focusNode  = FocusNode();
  bool _showHistory = false;
  bool _showTranslation = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _titleCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _annotate() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    final title = _titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : null;
    ref.read(readerProvider.notifier).annotate(text, title: title);
  }

  void _loadSeeded(String text, String title) {
    _textCtrl.text = text;
    _titleCtrl.clear();
    ref.read(readerProvider.notifier).annotate(text, title: title);
    FocusScope.of(context).unfocus();
  }

  void _showTokenSheet(Token token) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45, minChildSize: 0.3, maxChildSize: 0.9,
        expand: false,
        builder: (_, ctrl) => TokenDetailSheet(token: token, scrollController: ctrl),
      ),
    );
  }

  // Fix 5: long-press navigates to Graph tab
  void _longPressToken(Token token) {
    final notifier = ref.read(graphProvider.notifier);
    if (token.isCompound) {
      notifier.setFocalWord(token.text, token.text.split(''));
    } else {
      notifier.setFocal(token.text);
    }
    ref.read(tabIndexProvider.notifier).set(1);
  }

  @override
  Widget build(BuildContext context) {
    final c     = context.colors;
    final state = ref.watch(readerProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Smart Reader',
                      style: TextStyle(color: c.text, fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  Text('Interlinear Hán-Việt annotation',
                      style: TextStyle(color: c.textMuted, fontSize: 11)),
                ])),
                // Fix 4: correct independent toggle logic
                _ModeChip(label: 'PY',
                    active: state.mode == AnnotationMode.pinyin || state.mode == AnnotationMode.both,
                    color: const Color(0xFF38BDF8),
                    onTap: () {
                      final hasPY = state.mode == AnnotationMode.pinyin || state.mode == AnnotationMode.both;
                      final hasHV = state.mode == AnnotationMode.hanviet || state.mode == AnnotationMode.both;
                      if (hasPY) {
                        ref.read(readerProvider.notifier).setMode(
                            hasHV ? AnnotationMode.hanviet : AnnotationMode.none);
                      } else {
                        ref.read(readerProvider.notifier).setMode(
                            hasHV ? AnnotationMode.both : AnnotationMode.pinyin);
                      }
                    }),
                const SizedBox(width: 6),
                _ModeChip(label: 'HV',
                    active: state.mode == AnnotationMode.hanviet || state.mode == AnnotationMode.both,
                    onTap: () {
                      final hasPY = state.mode == AnnotationMode.pinyin || state.mode == AnnotationMode.both;
                      final hasHV = state.mode == AnnotationMode.hanviet || state.mode == AnnotationMode.both;
                      if (hasHV) {
                        ref.read(readerProvider.notifier).setMode(
                            hasPY ? AnnotationMode.pinyin : AnnotationMode.none);
                      } else {
                        ref.read(readerProvider.notifier).setMode(
                            hasPY ? AnnotationMode.both : AnnotationMode.hanviet);
                      }
                    }),
                const SizedBox(width: 8),
                // Fix 1: Settings button
                IconButton(
                  icon: Icon(Icons.tune, color: c.textMuted, size: 20),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _SettingsRoute())),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // History button
                IconButton(
                  icon: Icon(Icons.history, color: c.textMuted, size: 20),
                  onPressed: () => setState(() => _showHistory = !_showHistory),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ]),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  // Fix 6: SAMPLES label + Fix 2: Custom on its own line
                  Text('SAMPLES',
                      style: TextStyle(color: c.textMuted, fontSize: 9,
                          fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: kSeededTexts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final s = kSeededTexts[i];
                        return GestureDetector(
                          onTap: () => _loadSeeded(s.text, s.title),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.hanviet.withAlpha(26),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.hanviet.withAlpha(64), width: 0.5),
                            ),
                            child: Text(s.title,
                                style: const TextStyle(color: AppTheme.hanviet,
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Fix 2: Custom button on its own full-width line
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.semantic.withAlpha(128)),
                        foregroundColor: AppTheme.semantic,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Paste your own text',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: () {
                        _textCtrl.clear();
                        _titleCtrl.clear();
                        _focusNode.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Input area ────────────────────────────────────────
                  TextField(
                    controller: _textCtrl,
                    focusNode: _focusNode,
                    maxLines: 4,
                    style: TextStyle(color: c.text, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Paste Chinese text here…',
                      hintStyle: TextStyle(color: c.textMuted),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  // Title field — shown when text is non-empty
                  if (_textCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleCtrl,
                      style: TextStyle(color: c.text, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Title (optional) — saved to history',
                        hintStyle: TextStyle(color: c.textMuted, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.hanviet,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: state.isAnnotating
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: Text(state.isAnnotating
                          ? 'Annotating…' : 'Annotate · Extract Vocabulary',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13)),
                      onPressed: state.isAnnotating ? null : _annotate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Saved to history automatically',
                      style: TextStyle(color: c.textMuted, fontSize: 10),
                      textAlign: TextAlign.center),

                  // ── Annotated text ────────────────────────────────────
                  if (state.tokens.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border, width: 0.5),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(state.title,
                              style: TextStyle(color: c.textMuted, fontSize: 10,
                                  fontWeight: FontWeight.w700, letterSpacing: 1))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.semantic.withAlpha(26),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Annotated',
                                style: TextStyle(color: AppTheme.semantic, fontSize: 9,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        AnnotatedText(
                          tokens: state.tokens, mode: state.mode,
                          onTokenTap: _showTokenSheet,
                          onTokenLongPress: _longPressToken, // Fix 5
                        ),
                        const SizedBox(height: 12),
                        Text('Tap any word for details · long-press to add to graph',
                            style: TextStyle(color: c.textMuted, fontSize: 10),
                            textAlign: TextAlign.center),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // Fix 2: filled emerald button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.semantic,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.format_list_bulleted, size: 16),
                        label: const Text('Save to Decks',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        onPressed: () =>
                            ref.read(readerProvider.notifier).toggleHarvest(),
                      ),
                    ),

                    // Fix 8: English translation card
                    const SizedBox(height: 8),
                    _TranslationCard(
                      tokens: state.tokens,
                      aiTranslation: state.aiTranslation,
                      isTranslating: state.isTranslating,
                      expanded: _showTranslation,
                      onToggle: () => setState(() => _showTranslation = !_showTranslation),
                      onTranslate: () => ref.read(readerProvider.notifier).translateWithAi(),
                    ),
                  ],

                  // ── Harvest panel ─────────────────────────────────────
                  if (state.showHarvest) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: const HarvestPanel(),
                    ),
                  ],
                ],
              ),
            ),
          ]),

          // ── History overlay ───────────────────────────────────────────
          if (_showHistory)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showHistory = false),
                child: Container(color: Colors.black.withAlpha(128)),
              ),
            ),
          if (_showHistory)
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: MediaQuery.of(context).size.height * 0.6,
              child: HistoryList(
                  onClose: () => setState(() => _showHistory = false)),
            ),
        ]),
      ),
    );
  }
}

class _SettingsRoute extends StatelessWidget {
  const _SettingsRoute();
  @override
  Widget build(BuildContext context) => const SettingsScreen();
}

class _TranslationCard extends ConsumerStatefulWidget {
  final List<Token> tokens;
  final String? aiTranslation;
  final bool isTranslating;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onTranslate;

  const _TranslationCard({
    required this.tokens,
    required this.aiTranslation, required this.isTranslating,
    required this.expanded, required this.onToggle, required this.onTranslate,
  });

  @override
  ConsumerState<_TranslationCard> createState() => _TranslationCardState();
}

class _TranslationCardState extends ConsumerState<_TranslationCard> {
  bool _showGloss = false;

  String _buildGloss() {
    final parts = <String>[];
    for (final t in widget.tokens) {
      if (!t.isCjk) continue;
      final def = t.englishDef.isNotEmpty ? t.englishDef.split(';').first.trim() : '?';
      parts.add('${t.text}($def)');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (widget.tokens.isEmpty) return const SizedBox.shrink();

    final settingsAsync = ref.watch(llmSettingsProvider);
    final aiConfigured = settingsAsync.when(
      data: (s) => s.isConfigured, loading: () => false, error: (_, _) => false,
    );

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        InkWell(
          onTap: widget.onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Icons.translate, size: 14, color: AppTheme.phonetic),
              const SizedBox(width: 8),
              Text('English', style: TextStyle(color: c.text, fontSize: 13,
                  fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(widget.expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: c.textMuted, size: 18),
            ]),
          ),
        ),
        if (widget.expanded) ...[
          Divider(height: 0.5, thickness: 0.5, color: c.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Fix 6: AI translation FIRST
              if (widget.isTranslating)
                Shimmer.fromColors(
                  baseColor: AppTheme.phonetic.withAlpha(26),
                  highlightColor: AppTheme.phonetic.withAlpha(64),
                  child: Container(height: 60,
                      decoration: BoxDecoration(color: c.cardBg,
                          borderRadius: BorderRadius.circular(8))),
                )
              else if (widget.aiTranslation != null) ...[
                Text('AI Translation',
                    style: TextStyle(color: c.textMuted, fontSize: 9,
                        fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(widget.aiTranslation!,
                    style: TextStyle(color: c.text, fontSize: 13, height: 1.6)),
              ] else if (!aiConfigured)
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _SettingsRoute())),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.phonetic.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.phonetic.withAlpha(51)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: AppTheme.phonetic, size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Configure AI in Settings to translate →',
                          style: const TextStyle(color: AppTheme.phonetic,
                              fontSize: 12, fontWeight: FontWeight.w600))),
                    ]),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.phonetic),
                      foregroundColor: AppTheme.phonetic,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label: const Text('Translate with AI',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: widget.onTranslate,
                  ),
                ),

              // Fix 6: word-by-word gloss collapsible BELOW
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _showGloss = !_showGloss),
                child: Row(children: [
                  Text('Word-by-word',
                      style: TextStyle(color: c.textMuted, fontSize: 10,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Icon(_showGloss ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: c.textMuted, size: 14),
                ]),
              ),
              if (_showGloss) ...[
                const SizedBox(height: 6),
                Text(_buildGloss(),
                    style: TextStyle(color: c.textSub, fontSize: 11, height: 1.5)),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;

  const _ModeChip({
    required this.label, required this.active,
    required this.onTap, this.color = AppTheme.hanviet,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? color : color.withAlpha(64), width: 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? color : color.withAlpha(128),
                fontSize: 11, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

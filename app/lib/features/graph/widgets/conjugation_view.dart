import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ── Conjugation data ──────────────────────────────────────────────────────────

const _kStems = [
  (stem: '가', romanized: 'ga-', meaning: 'go'),
  (stem: '먹', romanized: 'meok-', meaning: 'eat'),
  (stem: '하', romanized: 'ha-', meaning: 'do'),
  (stem: '배우', romanized: 'bae-u-', meaning: 'learn'),
];

// [present, past, future] × [casual, polite, formal]
const _kForms = {
  '가': [
    (casual: '가',     polite: '가요',     formal: '갑니다'),
    (casual: '갔어',   polite: '갔어요',   formal: '갔습니다'),
    (casual: '갈게',   polite: '갈게요',   formal: '가겠습니다'),
  ],
  '먹': [
    (casual: '먹어',   polite: '먹어요',   formal: '먹습니다'),
    (casual: '먹었어', polite: '먹었어요', formal: '먹었습니다'),
    (casual: '먹을게', polite: '먹을게요', formal: '먹겠습니다'),
  ],
  '하': [
    (casual: '해',     polite: '해요',     formal: '합니다'),
    (casual: '했어',   polite: '했어요',   formal: '했습니다'),
    (casual: '할게',   polite: '할게요',   formal: '하겠습니다'),
  ],
  '배우': [
    (casual: '배워',   polite: '배워요',   formal: '배웁니다'),
    (casual: '배웠어', polite: '배웠어요', formal: '배웠습니다'),
    (casual: '배울게', polite: '배울게요', formal: '배우겠습니다'),
  ],
};

const _kTenses  = ['Present', 'Past', 'Future'];
const _kTenseColors = [Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B)];
const _kFormality = ['Casual', 'Polite', 'Formal'];

// ── Widget ────────────────────────────────────────────────────────────────────

class ConjugationView extends StatefulWidget {
  const ConjugationView({super.key});

  @override
  State<ConjugationView> createState() => _ConjugationViewState();
}

class _ConjugationViewState extends State<ConjugationView> {
  int _stemIdx     = 0;
  int _formalityIdx = 1; // default: Polite

  @override
  Widget build(BuildContext context) {
    final c    = context.colors;
    final stem = _kStems[_stemIdx];
    final forms = _kForms[stem.stem]!;

    return Column(children: [
      // Stem selector
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _kStems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final s      = _kStems[i];
              final active = i == _stemIdx;
              return GestureDetector(
                onTap: () => setState(() => _stemIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF818CF8).withAlpha(38)
                        : c.surf,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: active
                            ? const Color(0xFF818CF8)
                            : c.border,
                        width: active ? 1.5 : 0.5),
                  ),
                  child: RichText(text: TextSpan(children: [
                    TextSpan(text: s.stem,
                        style: TextStyle(
                            color: active ? const Color(0xFF818CF8) : c.text,
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    TextSpan(text: '-  ${s.meaning}',
                        style: TextStyle(color: c.textMuted, fontSize: 11)),
                  ])),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 10),

      // Formality chips
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: List.generate(_kFormality.length, (i) {
          final active = i == _formalityIdx;
          final colors = [
              const Color(0xFFEF4444), // casual red
              const Color(0xFFF59E0B), // polite amber
              const Color(0xFF6366F1), // formal indigo
          ];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _formalityIdx = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? colors[i].withAlpha(38) : c.surf,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? colors[i] : c.border,
                      width: active ? 1.5 : 0.5),
                ),
                child: Text(_kFormality[i],
                    style: TextStyle(
                        color: active ? colors[i] : c.textMuted,
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          );
        })),
      ),
      const SizedBox(height: 12),

      // 3-column tense grid
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            // Header row
            Row(children: List.generate(3, (i) => Expanded(
              child: Center(
                child: Text(_kTenses[i],
                    style: TextStyle(color: _kTenseColors[i],
                        fontSize: 11, fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ),
            ))),
            const SizedBox(height: 8),
            // Form cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(3, (tenseIdx) {
                final row   = forms[tenseIdx];
                final form  = _formalityIdx == 0 ? row.casual
                    : _formalityIdx == 1 ? row.polite
                    : row.formal;
                final color = _kTenseColors[tenseIdx];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _showBreakdown(context, stem.stem, form, _kTenses[tenseIdx], _kFormality[_formalityIdx], color),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withAlpha(80), width: 0.5),
                        ),
                        child: Column(children: [
                          Text(form,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: c.text, fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(_kTenses[tenseIdx],
                              style: TextStyle(color: color, fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Info hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.surf,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border, width: 0.5),
              ),
              child: Row(children: [
                Icon(Icons.touch_app_outlined, size: 13, color: c.textMuted),
                const SizedBox(width: 6),
                Text('Tap a cell to see the breakdown',
                    style: TextStyle(color: c.textMuted, fontSize: 11)),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }

  void _showBreakdown(BuildContext context, String stem, String form,
      String tense, String formality, Color color) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(form, style: TextStyle(color: c.text, fontSize: 40, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            _badge(tense, color),
            const SizedBox(width: 8),
            _badge(formality, const Color(0xFF818CF8)),
          ]),
          const SizedBox(height: 12),
          Text('Stem: $stem-', style: TextStyle(color: c.textMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Full form: $stem + conjugation ending → $form',
              style: TextStyle(color: c.textSub, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: color.withAlpha(38), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11,
        fontWeight: FontWeight.w700)),
  );
}

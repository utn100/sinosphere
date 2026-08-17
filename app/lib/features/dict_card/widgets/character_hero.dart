import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';

class CharacterHero extends StatelessWidget {
  final Character character;
  final int? hskLevel;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;
  final VoidCallback? onPracticeTap;

  const CharacterHero({
    super.key,
    required this.character,
    required this.hskLevel,
    required this.isBookmarked,
    required this.onBookmarkTap,
    this.onPracticeTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [c.cardBg, c.surf],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(character.symbol,
                            style: TextStyle(color: c.text, fontSize: 72,
                                fontWeight: FontWeight.w700, height: 1.0)),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Mandarin · Pinyin',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          Text(character.pinyin,
                              style: const TextStyle(color: Color(0xFF38BDF8),
                                  fontSize: 20, fontWeight: FontWeight.w500)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text('Hán-Việt',
                          style: TextStyle(color: c.textMuted, fontSize: 10,
                              fontWeight: FontWeight.w600, letterSpacing: 1)),
                      const SizedBox(width: 8),
                      Text(
                        character.hanViet.isNotEmpty ? character.hanViet : '—',
                        style: const TextStyle(color: AppTheme.hanviet, fontSize: 22,
                            fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ]),
                  ],
                ),
              ),
              Column(children: [
                GestureDetector(
                  onTap: onBookmarkTap,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(14)),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? AppTheme.hanviet : c.textMuted,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (onPracticeTap != null)
                  GestureDetector(
                    onTap: onPracticeTap,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.edit_outlined, color: c.textMuted, size: 20),
                    ),
                  ),
                if (onPracticeTap != null) const SizedBox(height: 8),
                if (hskLevel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.hanviet.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('HSK $hskLevel',
                        style: const TextStyle(color: AppTheme.hanviet,
                            fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Text(character.englishDef,
              style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surf.withAlpha(128), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _CognateCell(label: 'JP Onyomi', value: character.jpOnyomi ?? '—'),
              _divider(c.border),
              _CognateCell(label: 'KR Hanja',  value: character.hangul ?? '—'),
              _divider(c.border),
              _CognateCell(label: 'Strokes',
                  value: character.strokeCount > 0 ? '${character.strokeCount}' : '—'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color border) =>
      Container(width: 0.5, height: 32, color: border,
          margin: const EdgeInsets.symmetric(horizontal: 8));
}

class _CognateCell extends StatelessWidget {
  final String label, value;
  const _CognateCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(child: Column(children: [
      Text(label, style: TextStyle(color: c.textMuted, fontSize: 9,
          fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: c.text, fontSize: 12, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
    ]));
  }
}

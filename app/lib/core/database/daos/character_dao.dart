import 'package:drift/drift.dart' hide Component;
import '../database.dart';

class CharacterDetail {
  final Character character;
  final List<ComponentWithType> components;
  final List<CompoundWord> compounds;
  final int? hskLevel;
  const CharacterDetail({required this.character, required this.components, required this.compounds, this.hskLevel});
}

class ComponentWithType {
  final Component component;
  final String? componentType;
  final int position;
  const ComponentWithType({required this.component, required this.componentType, required this.position});
}

// ── DAO ──────────────────────────────────────────────────────────────────────
class CharacterDao {
  final AppDatabase _db;
  CharacterDao(this._db);

  Future<Character?> getBySymbol(String symbol) =>
      (_db.select(_db.characters)..where((c) => c.symbol.equals(symbol))).getSingleOrNull();

  Future<Character?> getById(String id) =>
      (_db.select(_db.characters)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// H5: search characters by symbol, pinyin, or han_viet for search fallback
  Future<List<Character>> searchCharacters(String query, {int limit = 5}) async {
    final q = query.trim().toLowerCase();
    return (_db.select(_db.characters)
          ..where((c) =>
              c.symbol.equals(query) |
              c.pinyin.lower().contains(q) |
              c.hanViet.lower().contains(q.toUpperCase()) |
              c.hanViet.contains(query.toUpperCase()))
          ..limit(limit))
        .get();
  }

  Future<List<ComponentWithType>> getComponents(String characterId) async {
    final rows = await (_db.select(_db.characterComponents)
          ..where((cc) => cc.characterId.equals(characterId))
          ..orderBy([(cc) => OrderingTerm.asc(cc.position)]))
        .get();
    final result = <ComponentWithType>[];
    for (final row in rows) {
      final comp = await (_db.select(_db.components)
            ..where((c) => c.id.equals(row.componentId)))
          .getSingleOrNull();
      if (comp != null) {
        result.add(ComponentWithType(
          component: comp,
          componentType: row.componentType,
          position: row.position,
        ));
      }
    }
    return result;
  }

  Future<List<CompoundWord>> getCompounds(String characterId, {int limit = 8}) async {
    return _db.customSelect('''
      SELECT cw.*
      FROM word_characters wc
      JOIN compound_words cw ON cw.id = wc.word_id
      WHERE wc.character_id = ?
      ORDER BY CASE WHEN cw.frequency_rank IS NOT NULL
                    THEN cw.frequency_rank ELSE 999999 END
      LIMIT ?
    ''', variables: [Variable(characterId), Variable(limit)],
        readsFrom: {_db.compoundWords, _db.wordCharacters})
        .map(_rowToCompound).get();
  }

  CompoundWord _rowToCompound(QueryRow row) => CompoundWord(
    id: row.read<String>('id'),
    simplified: row.read<String>('simplified'),
    traditional: row.readNullable<String>('traditional'),
    pinyin: row.read<String>('pinyin'),
    hangul: row.readNullable<String>('hangul'),
    hanViet: row.read<String>('han_viet'),
    hanVietResonance: row.read<String>('han_viet_resonance'),
    vietnameseNote: row.readNullable<String>('vietnamese_note'),
    englishDef: row.read<String>('english_def'),
    hskLevel: row.readNullable<int>('hsk_level'),
    frequencyRank: row.readNullable<int>('frequency_rank'),
    originType: row.read<String>('origin_type'),
    isCognateAnchor: row.read<int>('is_cognate_anchor'),
    aiGenerated: row.read<int>('ai_generated'),
    isSinoKorean: 0,
    batchim: 0,
    krVerified: 0,
    pos: null,
    krSynonyms: null,
    krAntonyms: null,
    krExample: null,
    topikInSource: 0,
  );

  Future<void> updateEtymologyStory(String characterId, String story) async {
    await (_db.update(_db.characters)..where((c) => c.id.equals(characterId)))
        .write(CharactersCompanion(etymologyStory: Value(story)));
  }

  Future<int?> getHskLevel(String characterId) async {
    final rows = await _db.customSelect('''
      SELECT MIN(cw.hsk_level) as hsk_level
      FROM word_characters wc
      JOIN compound_words cw ON cw.id = wc.word_id
      WHERE wc.character_id = ? AND cw.hsk_level IS NOT NULL
    ''', variables: [Variable(characterId)],
        readsFrom: {_db.wordCharacters, _db.compoundWords}).get();
    if (rows.isEmpty) return null;
    return rows.first.readNullable<int>('hsk_level');
  }

  Future<CharacterDetail?> getCharacterDetail(String symbol) async {
    final char = await getBySymbol(symbol);
    if (char == null) return null;
    final comps     = await getComponents(char.id);
    final compounds = await getCompounds(char.id);
    final hskLevel  = await getHskLevel(char.id);
    return CharacterDetail(character: char, components: comps, compounds: compounds, hskLevel: hskLevel);
  }
}

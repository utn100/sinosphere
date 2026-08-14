import 'package:drift/drift.dart';
import '../database.dart';

class GraphDao {
  final AppDatabase _db;
  GraphDao(this._db);

  /// Characters using a given symbol as their radical (for root-radical focal nodes)
  Future<List<Character>> getCharactersByRadical(String radical, {int limit = 12}) async {
    final rows = await _db.customSelect('''
      SELECT c.id, c.symbol, c.pinyin, c.hangul, c.han_viet,
             c.english_def, c.etymology_story, c.decomposition, c.radical,
             c.hsk_level, c.jp_onyomi, c.stroke_count,
             COUNT(DISTINCT wc.word_id) as word_cnt
      FROM characters c
      LEFT JOIN word_characters wc ON wc.character_id = c.id
      WHERE c.radical = ? AND c.symbol != ?
      GROUP BY c.id
      ORDER BY
        CASE WHEN c.hsk_level IS NOT NULL THEN c.hsk_level ELSE 99 END,
        word_cnt DESC
      LIMIT ?
    ''', variables: [Variable(radical), Variable(radical), Variable(limit)],
        readsFrom: {_db.characters, _db.wordCharacters}).get();

    return rows.map((r) => Character(
      id: r.read('id'), symbol: r.read('symbol'), pinyin: r.read('pinyin'),
      hangul: r.readNullable('hangul'), hanViet: r.read('han_viet'),
      englishDef: r.read('english_def'), etymologyStory: r.readNullable('etymology_story'),
      decomposition: r.readNullable('decomposition'), radical: r.readNullable('radical'),
      hskLevel: r.readNullable('hsk_level'), jpOnyomi: r.readNullable('jp_onyomi'),
      strokeCount: r.read('stroke_count'),
    )).toList();
  }

  /// Tier 2: sibling characters that share a given component, ordered by compound count
  Future<List<Character>> getSiblings(
      String componentId, String excludeCharId, {int limit = 8}) async {
    final rows = await _db.customSelect('''
      SELECT DISTINCT c.id, c.symbol, c.pinyin, c.hangul, c.han_viet,
             c.english_def, c.etymology_story, c.decomposition, c.radical,
             c.hsk_level, c.jp_onyomi, c.stroke_count
      FROM character_components cc
      JOIN characters c ON c.id = cc.character_id
      WHERE cc.component_id = ? AND cc.character_id != ?
      ORDER BY (
        SELECT COUNT(*) FROM word_characters wc WHERE wc.character_id = c.id
      ) DESC
      LIMIT ?
    ''', variables: [Variable(componentId), Variable(excludeCharId), Variable(limit)],
        readsFrom: {_db.characterComponents, _db.characters}).get();

    return rows.map((r) => Character(
      id: r.read('id'), symbol: r.read('symbol'), pinyin: r.read('pinyin'),
      hangul: r.readNullable('hangul'), hanViet: r.read('han_viet'),
      englishDef: r.read('english_def'), etymologyStory: r.readNullable('etymology_story'),
      decomposition: r.readNullable('decomposition'), radical: r.readNullable('radical'),
      hskLevel: r.readNullable('hsk_level'), jpOnyomi: r.readNullable('jp_onyomi'),
      strokeCount: r.read('stroke_count'),
    )).toList();
  }

  /// Tier 3: paginated compounds ordered by HV resonance then frequency
  Future<List<CompoundWord>> getCompoundsPaged(
      String characterId, {int offset = 0, int limit = 5}) async {
    final rows = await _db.customSelect('''
      SELECT cw.id, cw.simplified, cw.traditional, cw.pinyin, cw.hangul,
             cw.han_viet, cw.han_viet_resonance, cw.vietnamese_note,
             cw.english_def, cw.hsk_level, cw.frequency_rank,
             cw.origin_type, cw.is_cognate_anchor, cw.ai_generated
      FROM word_characters wc
      JOIN compound_words cw ON cw.id = wc.word_id
      WHERE wc.character_id = ?
      ORDER BY
        CASE cw.han_viet_resonance
          WHEN 'high'   THEN 0
          WHEN 'medium' THEN 1
          WHEN 'low'    THEN 2
          ELSE 3
        END,
        CASE WHEN cw.frequency_rank IS NOT NULL THEN cw.frequency_rank ELSE 999999 END
      LIMIT ? OFFSET ?
    ''', variables: [Variable(characterId), Variable(limit), Variable(offset)],
        readsFrom: {_db.wordCharacters, _db.compoundWords}).get();

    return rows.map((r) => CompoundWord(
      id: r.read('id'), simplified: r.read('simplified'),
      traditional: r.readNullable('traditional'), pinyin: r.read('pinyin'),
      hangul: r.readNullable('hangul'), hanViet: r.read('han_viet'),
      hanVietResonance: r.read('han_viet_resonance'),
      vietnameseNote: r.readNullable('vietnamese_note'),
      englishDef: r.read('english_def'), hskLevel: r.readNullable('hsk_level'),
      frequencyRank: r.readNullable('frequency_rank'),
      originType: r.read('origin_type'),
      isCognateAnchor: r.read('is_cognate_anchor'),
      aiGenerated: r.read('ai_generated'),
    )).toList();
  }

  /// Mode B: related words sharing HV root syllable OR sharing a character
  Future<List<CompoundWord>> getRelatedWords(
      String wordId, String hanViet, {int limit = 12}) async {
    // Extract first HV syllable for root matching
    final hvRoot = hanViet.trim().split(' ').first;

    final rows = await _db.customSelect('''
      SELECT DISTINCT cw.id, cw.simplified, cw.traditional, cw.pinyin, cw.hangul,
             cw.han_viet, cw.han_viet_resonance, cw.vietnamese_note,
             cw.english_def, cw.hsk_level, cw.frequency_rank,
             cw.origin_type, cw.is_cognate_anchor, cw.ai_generated
      FROM compound_words cw
      WHERE cw.id != ?
        AND (
          cw.han_viet LIKE ?
          OR cw.id IN (
            SELECT DISTINCT wc2.word_id
            FROM word_characters wc1
            JOIN word_characters wc2 ON wc2.character_id = wc1.character_id
                                    AND wc2.word_id != ?
            WHERE wc1.word_id = ?
          )
        )
      ORDER BY
        CASE cw.han_viet_resonance WHEN 'high' THEN 0 WHEN 'medium' THEN 1 ELSE 2 END,
        CASE WHEN cw.hsk_level IS NOT NULL THEN cw.hsk_level ELSE 99 END,
        CASE WHEN cw.frequency_rank IS NOT NULL THEN cw.frequency_rank ELSE 999999 END
      LIMIT ?
    ''', variables: [
      Variable(wordId),
      Variable('$hvRoot%'),
      Variable(wordId),
      Variable(wordId),
      Variable(limit),
    ], readsFrom: {_db.compoundWords, _db.wordCharacters}).get();

    return rows.map((r) => CompoundWord(
      id: r.read('id'), simplified: r.read('simplified'),
      traditional: r.readNullable('traditional'), pinyin: r.read('pinyin'),
      hangul: r.readNullable('hangul'), hanViet: r.read('han_viet'),
      hanVietResonance: r.read('han_viet_resonance'),
      vietnameseNote: r.readNullable('vietnamese_note'),
      englishDef: r.read('english_def'), hskLevel: r.readNullable('hsk_level'),
      frequencyRank: r.readNullable('frequency_rank'),
      originType: r.read('origin_type'),
      isCognateAnchor: r.read('is_cognate_anchor'),
      aiGenerated: r.read('ai_generated'),
    )).toList();
  }
}

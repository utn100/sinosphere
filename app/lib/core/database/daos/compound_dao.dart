import 'package:drift/drift.dart';
import '../database.dart';

class SearchResult {
  final String id;
  final String simplified;
  final String pinyin;
  final String hanViet;
  final String englishDef;
  final int? hskLevel;
  final int? frequencyRank;
  // Korean mode fields
  final String? hangul;
  final String? romaja;
  final int? topikLevel;
  final String? pos;
  final bool isNativeKorean;
  final String? krSynonyms;
  final String? krAntonyms;
  final String? krExample;

  const SearchResult({
    required this.id,
    required this.simplified,
    required this.pinyin,
    required this.hanViet,
    required this.englishDef,
    this.hskLevel,
    this.frequencyRank,
    this.hangul,
    this.romaja,
    this.topikLevel,
    this.pos,
    this.isNativeKorean = false,
    this.krSynonyms,
    this.krAntonyms,
    this.krExample,
  });
}

class CompoundDao {
  final AppDatabase _db;
  CompoundDao(this._db);

  Future<List<SearchResult>> search(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().replaceAll('"', '').replaceAll("'", '');

    // Try FTS5 first; fall back to LIKE if FTS fails (e.g. older Android SQLite)
    try {
      final ftsQuery = '"$q" OR $q*';
      final rows = await _db.customSelect('''
        SELECT cw.id, cw.simplified, cw.pinyin, cw.han_viet, cw.english_def,
               cw.hsk_level, cw.frequency_rank, cw.hangul, cw.romaja, cw.topik_level
        FROM words_fts
        JOIN compound_words cw ON cw.rowid = words_fts.rowid
        WHERE words_fts MATCH ?
        ORDER BY
          CASE WHEN cw.hsk_level IS NOT NULL THEN cw.hsk_level ELSE 99 END,
          CASE WHEN cw.frequency_rank IS NOT NULL THEN cw.frequency_rank ELSE 999999 END
        LIMIT ?
      ''', variables: [Variable(ftsQuery), Variable(limit)],
          readsFrom: {_db.compoundWords}).get();

      if (rows.isNotEmpty) return rows.map(_rowToResult).toList();
    } catch (_) {
      // FTS5 not available or query error — fall through to LIKE
    }

    final like = '%$q%';
    final rows = await _db.customSelect('''
      SELECT id, simplified, pinyin, han_viet, english_def,
             hsk_level, frequency_rank, hangul, romaja, topik_level
      FROM compound_words
      WHERE simplified LIKE ?
         OR pinyin LIKE ?
         OR han_viet LIKE ?
         OR english_def LIKE ?
      ORDER BY
        CASE WHEN hsk_level IS NOT NULL THEN hsk_level ELSE 99 END,
        CASE WHEN frequency_rank IS NOT NULL THEN frequency_rank ELSE 999999 END
      LIMIT ?
    ''', variables: [Variable(like), Variable(like), Variable(like), Variable(like), Variable(limit)],
        readsFrom: {_db.compoundWords}).get();

    return rows.map(_rowToResult).toList();
  }

  /// Korean-mode search: verified Sino-Korean words UNION native Korean words.
  Future<List<SearchResult>> searchKorean(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];
    final q    = query.trim().replaceAll('"', '').replaceAll("'", '');
    final like = '%$q%';

    // Sino-Korean: only kr_verified words
    final sinoRows = await _db.customSelect('''
      SELECT id, simplified, pinyin, han_viet, english_def,
             hsk_level, frequency_rank, hangul, romaja, topik_level, pos,
             0 AS is_native
      FROM compound_words
      WHERE kr_verified = 1
        AND (hangul LIKE ? OR romaja LIKE ? OR english_def LIKE ?)
      ORDER BY
        CASE WHEN topik_level IS NOT NULL THEN topik_level ELSE 99 END,
        CASE WHEN frequency_rank IS NOT NULL THEN frequency_rank ELSE 999999 END
      LIMIT ?
    ''', variables: [Variable(like), Variable(like), Variable(like), Variable(limit)],
        readsFrom: {_db.compoundWords}).get();

    // Native Korean: from korean_words table
    final nativeRows = await _db.customSelect('''
      SELECT id, hangul AS simplified, '' AS pinyin, '' AS han_viet, english_def,
             NULL AS hsk_level, frequency_rank, hangul, romaja, topik_level, pos,
             synonyms AS kr_synonyms, antonyms AS kr_antonyms,
             example_sentence AS kr_example,
             1 AS is_native
      FROM korean_words
      WHERE hangul LIKE ? OR romaja LIKE ? OR english_def LIKE ?
      ORDER BY
        CASE WHEN topik_level IS NOT NULL THEN topik_level ELSE 99 END,
        CASE WHEN frequency_rank IS NOT NULL THEN frequency_rank ELSE 999999 END
      LIMIT ?
    ''', variables: [Variable(like), Variable(like), Variable(like), Variable(limit)],
        readsFrom: {_db.koreanWords}).get();

    final all = [...sinoRows, ...nativeRows]
        .map(_rowToResultKr)
        .toList()
      ..sort((a, b) => (a.topikLevel ?? 99).compareTo(b.topikLevel ?? 99));
    return all.take(limit).toList();
  }

  SearchResult _rowToResultKr(QueryRow row) => SearchResult(
    id:             row.read<String>('id'),
    simplified:     row.read<String>('simplified'),
    pinyin:         row.read<String>('pinyin'),
    hanViet:        row.read<String>('han_viet'),
    englishDef:     row.read<String>('english_def'),
    hskLevel:       row.readNullable<int>('hsk_level'),
    frequencyRank:  row.readNullable<int>('frequency_rank'),
    hangul:         row.readNullable<String>('hangul'),
    romaja:         row.readNullable<String>('romaja'),
    topikLevel:     row.readNullable<int>('topik_level'),
    pos:            row.readNullable<String>('pos'),
    isNativeKorean: (row.readNullable<int>('is_native') ?? 0) == 1,
    // kr_* fields loaded lazily when dict card opens (avoids column-not-found on older devices)
    krSynonyms: null,
    krAntonyms: null,
    krExample:  null,
  );

  SearchResult _rowToResult(QueryRow row) => SearchResult(
    id:            row.read<String>('id'),
    simplified:    row.read<String>('simplified'),
    pinyin:        row.read<String>('pinyin'),
    hanViet:       row.read<String>('han_viet'),
    englishDef:    row.read<String>('english_def'),
    hskLevel:      row.readNullable<int>('hsk_level'),
    frequencyRank: row.readNullable<int>('frequency_rank'),
    hangul:        row.readNullable<String>('hangul'),
    romaja:        row.readNullable<String>('romaja'),
    topikLevel:    row.readNullable<int>('topik_level'),
    pos:           row.readNullable<String>('pos'),
  );

  Future<CompoundWord?> getBySimplified(String simplified) =>
      (_db.select(_db.compoundWords)..where((c) => c.simplified.equals(simplified)))
          .getSingleOrNull();

  Future<CompoundWord?> getById(String id) =>
      (_db.select(_db.compoundWords)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  Future<KoreanWord?> getKoreanWordById(String id) =>
      (_db.select(_db.koreanWords)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  Future<CompoundWord?> getByHangul(String hangul) =>
      (_db.select(_db.compoundWords)
        ..where((c) => c.hangul.equals(hangul))
        ..orderBy([(c) => OrderingTerm.asc(c.frequencyRank)])
        ..limit(1))
          .getSingleOrNull();

  /// Korean related compounds — words sharing any of the given hanja characters,
  /// excluding the current word. Ordered by topik_level then frequency_rank.
  Future<List<SearchResult>> getKoreanRelated(
    List<String> hanjaChars, {
    required String excludeId,
    int limit = 12,
  }) async {
    if (hanjaChars.isEmpty) return [];
    final placeholders = hanjaChars.map((_) => '?').join(', ');
    final rows = await _db.customSelect('''
      SELECT DISTINCT cw.id, cw.simplified, cw.pinyin, cw.han_viet, cw.english_def,
             cw.hsk_level, cw.frequency_rank, cw.hangul, cw.romaja, cw.topik_level
      FROM word_characters wc
      JOIN characters ch ON ch.id = wc.character_id
      JOIN compound_words cw ON cw.id = wc.word_id
      WHERE ch.symbol IN ($placeholders)
        AND cw.hangul IS NOT NULL
        AND cw.id != ?
      ORDER BY
        CASE WHEN cw.topik_level IS NOT NULL THEN cw.topik_level ELSE 99 END,
        CASE WHEN cw.frequency_rank IS NOT NULL THEN cw.frequency_rank ELSE 999999 END
      LIMIT ?
    ''', variables: [
      ...hanjaChars.map(Variable.new),
      Variable(excludeId),
      Variable(limit),
    ], readsFrom: {_db.compoundWords, _db.wordCharacters, _db.characters}).get();
    return rows.map(_rowToResult).toList();
  }

  Future<void> updateWordDetails(String wordId,
      {String? synonyms, String? antonyms, String? exampleSentence}) async {
    await (_db.update(_db.compoundWords)..where((c) => c.id.equals(wordId)))
        .write(CompoundWordsCompanion(
      synonyms:        Value(synonyms),
      antonyms:        Value(antonyms),
      exampleSentence: Value(exampleSentence),
    ));
  }
}

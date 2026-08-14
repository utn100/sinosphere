import 'package:drift/drift.dart';
import '../database.dart';

class SearchResult {
  final String simplified;
  final String pinyin;
  final String hanViet;
  final String englishDef;
  final int? hskLevel;
  final int? frequencyRank;

  const SearchResult({
    required this.simplified,
    required this.pinyin,
    required this.hanViet,
    required this.englishDef,
    this.hskLevel,
    this.frequencyRank,
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
        SELECT cw.simplified, cw.pinyin, cw.han_viet, cw.english_def,
               cw.hsk_level, cw.frequency_rank
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
      // FTS returned nothing — could be tokenizer issue; fall through to LIKE
    } catch (_) {
      // FTS5 not available or query error — fall through to LIKE
    }

    // LIKE fallback: searches simplified, pinyin (no tones), han_viet, english_def
    final like = '%$q%';
    final rows = await _db.customSelect('''
      SELECT simplified, pinyin, han_viet, english_def, hsk_level, frequency_rank
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

  SearchResult _rowToResult(QueryRow row) => SearchResult(
    simplified:    row.read<String>('simplified'),
    pinyin:        row.read<String>('pinyin'),
    hanViet:       row.read<String>('han_viet'),
    englishDef:    row.read<String>('english_def'),
    hskLevel:      row.readNullable<int>('hsk_level'),
    frequencyRank: row.readNullable<int>('frequency_rank'),
  );

  Future<CompoundWord?> getBySimplified(String simplified) =>
      (_db.select(_db.compoundWords)..where((c) => c.simplified.equals(simplified)))
          .getSingleOrNull();
}

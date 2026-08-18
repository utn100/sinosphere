import 'package:drift/drift.dart';
import '../database.dart';

const String bookmarksCollectionId   = 'bookmarks';
const String bookmarksCollectionName = 'Bookmarks';

class CollectionItem {
  final String id;
  final String display;   // simplified (Chinese) or symbol
  final String? hangul;   // Korean reading — non-null for compound words with hangul
  final String hanViet;
  final String pinyin;
  final String englishDef;
  final bool isChar;
  const CollectionItem({
    required this.id, required this.display, required this.hanViet,
    required this.pinyin, required this.englishDef, required this.isChar,
    this.hangul,
  });
}

class CollectionDao {
  final AppDatabase _db;
  CollectionDao(this._db);

  Future<void> ensureBookmarksCollection() async {
    final existing = await (_db.select(_db.userCollections)
          ..where((c) => c.id.equals(bookmarksCollectionId)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.userCollections).insert(UserCollectionsCompanion(
        id: const Value(bookmarksCollectionId),
        name: const Value(bookmarksCollectionName),
        icon: const Value('🔖'),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    }
  }

  Future<List<UserCollection>> getAllCollections() =>
      _db.select(_db.userCollections).get();

  Future<void> createCollection(String id, String name, {String? icon}) async {
    await _db.into(_db.userCollections).insert(UserCollectionsCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteCollection(String id) async {
    await (_db.delete(_db.userCollectionWords)
          ..where((w) => w.collectionId.equals(id)))
        .go();
    await (_db.delete(_db.userCollections)..where((c) => c.id.equals(id))).go();
  }

  Future<bool> isBookmarked(String wordId) async {
    final row = await (_db.select(_db.userCollectionWords)
          ..where((w) => w.collectionId.equals(bookmarksCollectionId))
          ..where((w) => w.wordId.equals(wordId)))
        .getSingleOrNull();
    return row != null;
  }

  /// Items in a user collection — covers both character IDs and compound word IDs
  Future<List<CollectionItem>> getCollectionItems(String collectionId) async {
    final rows = await _db.customSelect('''
      SELECT src, id, display, han_viet, pinyin, english_def, hangul FROM (
        SELECT 1 as src, c.id, c.symbol as display, c.han_viet, c.pinyin, c.english_def, NULL as hangul, ucw.added_at
        FROM user_collection_words ucw
        JOIN characters c ON c.id = ucw.word_id
        WHERE ucw.collection_id = ?
        UNION ALL
        SELECT 2 as src, cw.id, cw.simplified as display,
               cw.han_viet, cw.pinyin, cw.english_def, cw.hangul, ucw.added_at
        FROM user_collection_words ucw
        JOIN compound_words cw ON cw.id = ucw.word_id
        WHERE ucw.collection_id = ?
        UNION ALL
        SELECT 3 as src, kw.id, kw.hangul as display,
               '' as han_viet, COALESCE(kw.romaja, '') as pinyin, kw.english_def, kw.hangul, ucw.added_at
        FROM user_collection_words ucw
        JOIN korean_words kw ON kw.id = ucw.word_id
        WHERE ucw.collection_id = ?
      ) ORDER BY added_at DESC LIMIT 40
    ''', variables: [
      Variable(collectionId),
      Variable(collectionId),
      Variable(collectionId),
    ],
        readsFrom: {_db.userCollectionWords, _db.characters, _db.compoundWords, _db.koreanWords}).get();

    return rows.map((r) => CollectionItem(
      id:         r.read<String>('id'),
      display:    r.read<String>('display'),
      hangul:     r.readNullable<String>('hangul'),
      hanViet:    r.read<String>('han_viet'),
      pinyin:     r.read<String>('pinyin'),
      englishDef: r.read<String>('english_def'),
      isChar:     r.read<int>('src') == 1,
    )).toList();
  }

  static const _memorizedId = 'memorized';

  Future<void> _ensureMemorizedCollection() async {
    final existing = await (_db.select(_db.userCollections)
          ..where((c) => c.id.equals(_memorizedId)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.userCollections).insert(UserCollectionsCompanion(
        id: const Value(_memorizedId),
        name: const Value('Memorized'),
        icon: const Value('✅'),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    }
  }

  Future<Set<String>> getMemorizedWordIds(int hskLevel) async {
    final rows = await _db.customSelect('''
      SELECT ucw.word_id FROM user_collection_words ucw
      JOIN compound_words cw ON cw.id = ucw.word_id
      WHERE ucw.collection_id = ? AND cw.hsk_level = ?
    ''', variables: [const Variable(_memorizedId), Variable(hskLevel)],
        readsFrom: {_db.userCollectionWords, _db.compoundWords}).get();
    return rows.map((r) => r.read<String>('word_id')).toSet();
  }

  /// Returns memorized IDs scoped to a specific TOPIK band — never bleeds into HSK.
  Future<Set<String>> getMemorizedWordIdsByTopikLevels(List<int> levels) async {
    final placeholders = levels.map((_) => '?').join(',');
    final r1 = await _db.customSelect(
      'SELECT ucw.word_id FROM user_collection_words ucw '
      'JOIN compound_words cw ON cw.id = ucw.word_id '
      'WHERE ucw.collection_id = ? AND cw.topik_level IN ($placeholders) '
      'AND cw.topik_in_source = 1 AND LENGTH(cw.hangul) >= 2',
      variables: [const Variable(_memorizedId), ...levels.map(Variable.new)],
      readsFrom: {_db.userCollectionWords, _db.compoundWords},
    ).get();
    final r2 = await _db.customSelect(
      'SELECT ucw.word_id FROM user_collection_words ucw '
      'JOIN korean_words kw ON kw.id = ucw.word_id '
      'WHERE ucw.collection_id = ? AND kw.topik_level IN ($placeholders)',
      variables: [const Variable(_memorizedId), ...levels.map(Variable.new)],
      readsFrom: {_db.userCollectionWords, _db.koreanWords},
    ).get();
    return {
      ...r1.map((r) => r.read<String>('word_id')),
      ...r2.map((r) => r.read<String>('word_id')),
    };
  }

  Future<int> getMemorizedCountByHsk(int level) async {
    final row = await _db.customSelect('''
      SELECT COUNT(*) as cnt FROM user_collection_words ucw
      JOIN compound_words cw ON cw.id = ucw.word_id
      WHERE ucw.collection_id = ? AND cw.hsk_level = ?
    ''', variables: [const Variable(_memorizedId), Variable(level)],
        readsFrom: {_db.userCollectionWords, _db.compoundWords}).getSingle();
    return row.read<int>('cnt');
  }

  Future<int> getMemorizedCountByTopik(List<int> levels) async {
    final placeholders = levels.map((_) => '?').join(', ');
    final r1 = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM user_collection_words ucw '
      'JOIN compound_words cw ON cw.id = ucw.word_id '
      'WHERE ucw.collection_id = ? AND cw.topik_level IN ($placeholders) '
      'AND cw.topik_in_source = 1 AND LENGTH(cw.hangul) >= 2',
      variables: [const Variable(_memorizedId), ...levels.map(Variable.new)],
      readsFrom: {_db.userCollectionWords, _db.compoundWords},
    ).getSingle();
    final r2 = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM user_collection_words ucw '
      'JOIN korean_words kw ON kw.id = ucw.word_id '
      'WHERE ucw.collection_id = ? AND kw.topik_level IN ($placeholders)',
      variables: [const Variable(_memorizedId), ...levels.map(Variable.new)],
      readsFrom: {_db.userCollectionWords, _db.koreanWords},
    ).getSingle();
    return r1.read<int>('cnt') + r2.read<int>('cnt');
  }

  Future<void> toggleMemorized(String wordId) async {
    await _ensureMemorizedCollection();
    final existing = await (_db.select(_db.userCollectionWords)
          ..where((w) => w.collectionId.equals(_memorizedId))
          ..where((w) => w.wordId.equals(wordId)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.delete(_db.userCollectionWords)
            ..where((w) => w.collectionId.equals(_memorizedId))
            ..where((w) => w.wordId.equals(wordId)))
          .go();
    } else {
      await _db.into(_db.userCollectionWords).insert(
        UserCollectionWordsCompanion(
          collectionId: const Value(_memorizedId),
          wordId: Value(wordId),
          addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<void> resetMemorized(int hskLevel) async {
    await _db.customStatement('''
      DELETE FROM user_collection_words
      WHERE collection_id = '$_memorizedId'
      AND word_id IN (
        SELECT id FROM compound_words WHERE hsk_level = $hskLevel
      )
    ''');
  }

  Future<Set<String>> getMemorizedWordIdsByTopik(int topikLevel) async {
    final rows = await _db.customSelect('''
      SELECT ucw.word_id FROM user_collection_words ucw
      JOIN compound_words cw ON cw.id = ucw.word_id
      WHERE ucw.collection_id = ? AND cw.topik_level = ?
    ''', variables: [const Variable(_memorizedId), Variable(topikLevel)],
        readsFrom: {_db.userCollectionWords, _db.compoundWords}).get();
    return rows.map((r) => r.read<String>('word_id')).toSet();
  }

  Future<void> resetMemorizedByTopik(int topikLevel) async {
    await _db.customStatement('''
      DELETE FROM user_collection_words
      WHERE collection_id = '$_memorizedId'
      AND word_id IN (
        SELECT id FROM compound_words WHERE topik_level = $topikLevel
      )
    ''');
    await _db.customStatement('''
      DELETE FROM user_collection_words
      WHERE collection_id = '$_memorizedId'
      AND word_id IN (
        SELECT id FROM korean_words WHERE topik_level = $topikLevel
      )
    ''');
  }

  /// Returns ALL word IDs in the memorized collection — used by topic/shared collections.
  Future<Set<String>> getAllMemorizedWordIds() async {
    final rows = await _db.customSelect(
      'SELECT word_id FROM user_collection_words WHERE collection_id = ?',
      variables: [const Variable(_memorizedId)],
      readsFrom: {_db.userCollectionWords},
    ).get();
    return rows.map((r) => r.read<String>('word_id')).toSet();
  }

  /// Removes specific word IDs from the memorized collection (for topic/TOPIK resets).
  Future<void> resetMemorizedForWords(List<String> wordIds) async {
    if (wordIds.isEmpty) return;
    for (final id in wordIds) {
      await (_db.delete(_db.userCollectionWords)
            ..where((w) => w.collectionId.equals(_memorizedId))
            ..where((w) => w.wordId.equals(id)))
          .go();
    }
  }

  // ── Topic collections ─────────────────────────────────────────────────────

  static const _topicWhere = {
    'nature':   "topic_tag LIKE '%nature%' AND han_viet_resonance IN ('high','medium')",
    'body':     "topic_tag LIKE '%body%' AND han_viet_resonance IN ('high','medium')",
    'city':     "topic_tag LIKE '%city%' AND han_viet_resonance IN ('high','medium')",
    'emotions': "topic_tag LIKE '%emotions%' AND han_viet_resonance IN ('high','medium')",
    'time':     "topic_tag LIKE '%time%' AND han_viet_resonance IN ('high','medium')",
    'family':   "topic_tag LIKE '%family%' AND han_viet_resonance IN ('high','medium')",
    'learning': "topic_tag LIKE '%learning%' AND han_viet_resonance IN ('high','medium')",
    'travel':   "topic_tag LIKE '%travel%' AND han_viet_resonance IN ('high','medium')",
    'food':     "topic_tag LIKE '%food%' AND han_viet_resonance IN ('high','medium')",
    'business': "topic_tag LIKE '%business%' AND han_viet_resonance IN ('high','medium')",
    'cognates': "is_cognate_anchor = 1",
    'songs':    "hsk_level <= 3 AND han_viet_resonance = 'medium'",
  };

  Future<int> getTopicWordCount(String topicId, {bool krOnly = false}) async {
    final where = _topicWhere[topicId];
    if (where == null) return 0;
    final krFilter = krOnly ? ' AND kr_verified = 1 AND LENGTH(hangul) >= 2' : '';
    final row = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM compound_words WHERE $where$krFilter',
      readsFrom: {_db.compoundWords},
    ).getSingle();
    return row.read<int>('cnt');
  }

  Future<List<CompoundWord>> getTopicWords(String topicId,
      {int offset = 0, int limit = 50, bool krOnly = false}) async {
    final where = _topicWhere[topicId];
    if (where == null) return [];
    final krFilter = krOnly ? ' AND kr_verified = 1 AND LENGTH(hangul) >= 2' : '';
    final rows = await _db.customSelect('''
      SELECT id, simplified, traditional, pinyin, hangul, han_viet,
             han_viet_resonance, vietnamese_note, english_def,
             hsk_level, frequency_rank, origin_type, is_cognate_anchor, ai_generated
      FROM compound_words
      WHERE $where$krFilter
      ORDER BY
        CASE han_viet_resonance WHEN 'high' THEN 0 WHEN 'medium' THEN 1 ELSE 2 END,
        CASE WHEN frequency_rank IS NOT NULL THEN frequency_rank ELSE 999999 END
      LIMIT $limit OFFSET $offset
    ''', readsFrom: {_db.compoundWords}).get();

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
      isSinoKorean: 0,
      batchim: 0,
      krVerified: 0,
      pos: null,
      krSynonyms: null,
      krAntonyms: null,
      krExample: null,
      topikInSource: 0,
    )).toList();
  }

  /// Total word count for an HSK level
  Future<int> getHskWordCount(int level) async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM compound_words WHERE hsk_level = ?',
      variables: [Variable(level)],
      readsFrom: {_db.compoundWords},
    ).getSingle();
    return row.read<int>('cnt');
  }

  /// Compound words for an HSK level — paginated
  Future<List<CompoundWord>> getHskWords(int level,
      {int offset = 0, int limit = 50}) async {
    final rows = await _db.customSelect('''
      SELECT id, simplified, traditional, pinyin, hangul, han_viet,
             han_viet_resonance, vietnamese_note, english_def,
             hsk_level, frequency_rank, origin_type, is_cognate_anchor, ai_generated
      FROM compound_words
      WHERE hsk_level = ?
      ORDER BY CASE WHEN frequency_rank IS NOT NULL THEN frequency_rank ELSE 999999 END
      LIMIT ? OFFSET ?
    ''', variables: [Variable(level), Variable(limit), Variable(offset)],
        readsFrom: {_db.compoundWords}).get();

    return rows.map((r) => CompoundWord(
      id: r.read('id'), simplified: r.read('simplified'),
      traditional: r.readNullable('traditional'), pinyin: r.read('pinyin'),
      hangul: r.readNullable('hangul'), hanViet: r.read('han_viet'),
      hanVietResonance: r.read('han_viet_resonance'),
      vietnameseNote: r.readNullable('vietnamese_note'),
      englishDef: r.read('english_def'),
      hskLevel: r.readNullable('hsk_level'),
      frequencyRank: r.readNullable('frequency_rank'),
      originType: r.read('origin_type'),
      isCognateAnchor: r.read('is_cognate_anchor'),
      aiGenerated: r.read('ai_generated'),
      isSinoKorean: 0,
      batchim: 0,
      krVerified: 0,
      pos: null,
      krSynonyms: null,
      krAntonyms: null,
      krExample: null,
      topikInSource: 0,
    )).toList();
  }

  /// Check if a compound word (by its compound_words.id) is bookmarked
  Future<bool> isWordBookmarked(String wordId) => isBookmarked(wordId);

  /// Toggle bookmark for a compound word
  Future<void> toggleWordBookmark(String wordId) => toggleBookmark(wordId);

  Future<void> toggleBookmark(String wordId) async {
    await ensureBookmarksCollection();
    final existing = await (_db.select(_db.userCollectionWords)
          ..where((w) => w.collectionId.equals(bookmarksCollectionId))
          ..where((w) => w.wordId.equals(wordId)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.delete(_db.userCollectionWords)
            ..where((w) => w.collectionId.equals(bookmarksCollectionId))
            ..where((w) => w.wordId.equals(wordId)))
          .go();
    } else {
      await _db.into(_db.userCollectionWords).insert(
        UserCollectionWordsCompanion(
          collectionId: const Value(bookmarksCollectionId),
          wordId: Value(wordId),
          addedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  Future<void> addToCollection(String collectionId, String wordId) async {
    await _db.into(_db.userCollectionWords).insertOnConflictUpdate(
      UserCollectionWordsCompanion(
        collectionId: Value(collectionId),
        wordId: Value(wordId),
        addedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<List<String>> getBookmarkedSymbols() async {
    final rows = await _db.customSelect('''
      SELECT display FROM (
        SELECT c.symbol as display, ucw.added_at
        FROM user_collection_words ucw
        JOIN characters c ON c.id = ucw.word_id
        WHERE ucw.collection_id = ?
        UNION ALL
        SELECT COALESCE(cw.hangul, cw.simplified) as display, ucw.added_at
        FROM user_collection_words ucw
        JOIN compound_words cw ON cw.id = ucw.word_id
        WHERE ucw.collection_id = ?
        UNION ALL
        SELECT kw.hangul as display, ucw.added_at
        FROM user_collection_words ucw
        JOIN korean_words kw ON kw.id = ucw.word_id
        WHERE ucw.collection_id = ?
      ) ORDER BY added_at DESC LIMIT 20
    ''',
        variables: [
          const Variable(bookmarksCollectionId),
          const Variable(bookmarksCollectionId),
          const Variable(bookmarksCollectionId),
        ],
        readsFrom: {_db.userCollectionWords, _db.characters, _db.compoundWords, _db.koreanWords}).get();
    return rows.map((r) => r.read<String>('display')).toList();
  }

  /// Returns character, compound word, and native Korean word bookmarks, most recent first.
  Future<List<CollectionItem>> getBookmarkedItems() async {
    final rows = await _db.customSelect('''
      SELECT kind, id, display, han_viet, pinyin, english_def, hangul FROM (
        SELECT 'char' as kind, c.id, c.symbol as display,
               c.han_viet, c.pinyin, c.english_def, NULL as hangul, ucw.added_at
        FROM user_collection_words ucw
        JOIN characters c ON c.id = ucw.word_id
        WHERE ucw.collection_id = ?
        UNION ALL
        SELECT 'word' as kind, cw.id, cw.simplified as display,
               cw.han_viet, cw.pinyin, cw.english_def, cw.hangul, ucw.added_at
        FROM user_collection_words ucw
        JOIN compound_words cw ON cw.id = ucw.word_id
        WHERE ucw.collection_id = ?
        UNION ALL
        SELECT 'krword' as kind, kw.id, kw.hangul as display,
               '' as han_viet, kw.romaja as pinyin, kw.english_def, kw.hangul, ucw.added_at
        FROM user_collection_words ucw
        JOIN korean_words kw ON kw.id = ucw.word_id
        WHERE ucw.collection_id = ?
      ) ORDER BY added_at DESC LIMIT 40
    ''',
        variables: [
          const Variable(bookmarksCollectionId),
          const Variable(bookmarksCollectionId),
          const Variable(bookmarksCollectionId),
        ],
        readsFrom: {_db.userCollectionWords, _db.characters, _db.compoundWords, _db.koreanWords}).get();
    return rows.map((r) => CollectionItem(
      id:         r.read('id'),
      display:    r.read('display'),
      hangul:     r.readNullable('hangul'),
      hanViet:    r.read('han_viet'),
      pinyin:     r.read('pinyin'),
      englishDef: r.read('english_def'),
      isChar:     r.read<String>('kind') == 'char',    )).toList();
  }

  // ─── TOPIK ────────────────────────────────────────────────────────────────

  Future<int> getTopikWordCount(int level) async {
    final r1 = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM compound_words WHERE topik_level = ? AND topik_in_source = 1 AND LENGTH(hangul) >= 2',
      variables: [Variable(level)],
      readsFrom: {_db.compoundWords},
    ).getSingle();
    final r2 = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM korean_words WHERE topik_level = ?',
      variables: [Variable(level)],
      readsFrom: {_db.koreanWords},
    ).getSingle();
    return r1.read<int>('cnt') + r2.read<int>('cnt');
  }

  Future<List<CompoundWord>> getTopikWords(int level,
      {int offset = 0, int limit = 50}) async {
    final rows = await _db.customSelect('''
      SELECT * FROM (
        SELECT id, simplified, NULL as traditional, pinyin, hangul, han_viet,
               'medium' as han_viet_resonance, NULL as vietnamese_note, english_def,
               NULL as hsk_level, frequency_rank, 'sino_chinese' as origin_type,
               0 as is_cognate_anchor, 0 as ai_generated
        FROM compound_words
        WHERE topik_level = ? AND topik_in_source = 1 AND LENGTH(hangul) >= 2
        UNION ALL
        SELECT id, hangul as simplified, NULL as traditional,
               COALESCE(romaja, '') as pinyin, hangul, '' as han_viet,
               'medium' as han_viet_resonance, NULL as vietnamese_note, english_def,
               NULL as hsk_level, frequency_rank, 'native_korean' as origin_type,
               0 as is_cognate_anchor, 0 as ai_generated
        FROM korean_words
        WHERE topik_level = ?
      )
      ORDER BY CASE WHEN frequency_rank IS NOT NULL THEN frequency_rank ELSE 999999 END
      LIMIT ? OFFSET ?
    ''', variables: [Variable(level), Variable(level), Variable(limit), Variable(offset)],
        readsFrom: {_db.compoundWords, _db.koreanWords}).get();

    return rows.map(_topikRowToWord).toList();
  }

  CompoundWord _topikRowToWord(QueryRow r) => CompoundWord(
    id: r.read('id'), simplified: r.read('simplified'),
    traditional: r.readNullable('traditional'), pinyin: r.read('pinyin'),
    hangul: r.readNullable('hangul'), hanViet: r.read('han_viet'),
    hanVietResonance: r.read('han_viet_resonance'),
    vietnameseNote: r.readNullable('vietnamese_note'),
    englishDef: r.read('english_def'),
    hskLevel: r.readNullable('hsk_level'),
    frequencyRank: r.readNullable('frequency_rank'),
    originType: r.read('origin_type'),
    isCognateAnchor: r.read('is_cognate_anchor'),
    aiGenerated: r.read('ai_generated'),
    isSinoKorean: 0, batchim: 0, krVerified: 0, pos: null,
    krSynonyms: null, krAntonyms: null, krExample: null, topikInSource: 0,
  );

  /// Word count for multiple TOPIK levels combined (e.g. T5+T6 for Advanced band).
  Future<int> getTopikWordCountMulti(List<int> levels) async {
    final placeholders = levels.map((_) => '?').join(', ');
    final r1 = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM compound_words WHERE topik_level IN ($placeholders) AND topik_in_source = 1 AND LENGTH(hangul) >= 2',
      variables: levels.map(Variable.new).toList(),
      readsFrom: {_db.compoundWords},
    ).getSingle();
    final r2 = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM korean_words WHERE topik_level IN ($placeholders)',
      variables: levels.map(Variable.new).toList(),
      readsFrom: {_db.koreanWords},
    ).getSingle();
    return r1.read<int>('cnt') + r2.read<int>('cnt');
  }

  /// Words for multiple TOPIK levels combined — paginated.
  Future<List<CompoundWord>> getTopikWordsMulti(List<int> levels,
      {int offset = 0, int limit = 50}) async {
    final placeholders = levels.map((_) => '?').join(', ');
    final rows = await _db.customSelect('''
      SELECT * FROM (
        SELECT id, simplified, NULL as traditional, pinyin, hangul, han_viet,
               'medium' as han_viet_resonance, NULL as vietnamese_note, english_def,
               NULL as hsk_level, frequency_rank, 'sino_chinese' as origin_type,
               0 as is_cognate_anchor, 0 as ai_generated
        FROM compound_words
        WHERE topik_level IN ($placeholders) AND topik_in_source = 1 AND LENGTH(hangul) >= 2
        UNION ALL
        SELECT id, hangul as simplified, NULL as traditional,
               COALESCE(romaja, '') as pinyin, hangul, '' as han_viet,
               'medium' as han_viet_resonance, NULL as vietnamese_note, english_def,
               NULL as hsk_level, frequency_rank, 'native_korean' as origin_type,
               0 as is_cognate_anchor, 0 as ai_generated
        FROM korean_words
        WHERE topik_level IN ($placeholders)
      )
      ORDER BY CASE WHEN frequency_rank IS NOT NULL THEN frequency_rank ELSE 999999 END
      LIMIT ? OFFSET ?
    ''', variables: [
      ...levels.map(Variable.new),
      ...levels.map(Variable.new),
      Variable(limit), Variable(offset),
    ],
        readsFrom: {_db.compoundWords, _db.koreanWords}).get();

    return rows.map(_topikRowToWord).toList();
  }

  /// Random words for daily practice — from bookmarks/memorized first, fallback to HSK 1-3.
  Future<List<CompoundWord>> getRandomPracticeWords(int n) async {
    final rows = await _db.customSelect('''
      SELECT id, simplified, traditional, pinyin, hangul, han_viet,
             han_viet_resonance, vietnamese_note, english_def,
             hsk_level, frequency_rank, origin_type, is_cognate_anchor, ai_generated
      FROM compound_words
      WHERE id IN (
        SELECT word_id FROM user_collection_words
        WHERE collection_id IN ('bookmarks', 'memorized')
      )
      ORDER BY RANDOM() LIMIT ?
    ''', variables: [Variable(n)], readsFrom: {_db.compoundWords, _db.userCollectionWords}).get();

    // If not enough saved words, fill with random HSK 1-3
    if (rows.length < n) {
      final exclude = rows.map((r) => "'${r.read<String>('id')}'").join(',');
      final excludeClause = exclude.isEmpty ? '' : 'AND id NOT IN ($exclude)';
      final fallback = await _db.customSelect('''
        SELECT id, simplified, traditional, pinyin, hangul, han_viet,
               han_viet_resonance, vietnamese_note, english_def,
               hsk_level, frequency_rank, origin_type, is_cognate_anchor, ai_generated
        FROM compound_words
        WHERE hsk_level <= 3 $excludeClause
        ORDER BY RANDOM() LIMIT ?
      ''', variables: [Variable(n - rows.length)], readsFrom: {_db.compoundWords}).get();
      return [...rows, ...fallback].map((r) => CompoundWord(
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
        isSinoKorean: 0, batchim: 0, krVerified: 0, pos: null,
        krSynonyms: null, krAntonyms: null, krExample: null, topikInSource: 0,
      )).toList();
    }

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
      isSinoKorean: 0, batchim: 0, krVerified: 0, pos: null,
      krSynonyms: null, krAntonyms: null, krExample: null, topikInSource: 0,
    )).toList();
  }

  /// Random KR words for daily practice — TOPIK verified words only (compound + native).
  Future<List<CompoundWord>> getRandomKrPracticeWords(int n) async {
    final rows = await _db.customSelect('''
      SELECT * FROM (
        SELECT id, simplified, NULL as traditional, pinyin, hangul, han_viet,
               'medium' as han_viet_resonance, NULL as vietnamese_note, english_def,
               NULL as hsk_level, frequency_rank, 'sino_chinese' as origin_type,
               0 as is_cognate_anchor, 0 as ai_generated
        FROM compound_words
        WHERE topik_in_source = 1 AND LENGTH(hangul) >= 2
        UNION ALL
        SELECT id, hangul as simplified, NULL as traditional,
               COALESCE(romaja,'') as pinyin, hangul, '' as han_viet,
               'medium' as han_viet_resonance, NULL as vietnamese_note, english_def,
               NULL as hsk_level, frequency_rank, 'native_korean' as origin_type,
               0 as is_cognate_anchor, 0 as ai_generated
        FROM korean_words
        WHERE topik_level IS NOT NULL
      )
      ORDER BY RANDOM() LIMIT ?
    ''', variables: [Variable(n)],
        readsFrom: {_db.compoundWords, _db.koreanWords}).get();
    return rows.map(_topikRowToWord).toList();
  }
}

import 'package:drift/drift.dart';
import '../database.dart';

const String bookmarksCollectionId   = 'bookmarks';
const String bookmarksCollectionName = 'Bookmarks';

class CollectionItem {
  final String id;
  final String display;
  final String hanViet;
  final String pinyin;
  final String englishDef;
  final bool isChar;
  const CollectionItem({
    required this.id, required this.display, required this.hanViet,
    required this.pinyin, required this.englishDef, required this.isChar,
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
      SELECT 1 as src, c.id, c.symbol as display, c.han_viet, c.pinyin, c.english_def
      FROM user_collection_words ucw
      JOIN characters c ON c.id = ucw.word_id
      WHERE ucw.collection_id = ?
      UNION ALL
      SELECT 2 as src, cw.id, cw.simplified as display, cw.han_viet, cw.pinyin, cw.english_def
      FROM user_collection_words ucw
      JOIN compound_words cw ON cw.id = ucw.word_id
      WHERE ucw.collection_id = ?
      ORDER BY src, display
    ''', variables: [Variable(collectionId), Variable(collectionId)],
        readsFrom: {_db.userCollectionWords, _db.characters, _db.compoundWords}).get();

    return rows.map((r) => CollectionItem(
      id: r.read<String>('id'),
      display: r.read<String>('display'),
      hanViet: r.read<String>('han_viet'),
      pinyin: r.read<String>('pinyin'),
      englishDef: r.read<String>('english_def'),
      isChar: r.read<int>('src') == 1,
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

  // ── Topic collections ─────────────────────────────────────────────────────

  static const _topicWhere = {
    'nature':   "(english_def LIKE '%mountain%' OR english_def LIKE '%water%' OR "
                "english_def LIKE '%sky%' OR english_def LIKE '%flower%' OR "
                "english_def LIKE '%tree%' OR english_def LIKE '%earth%' OR "
                "english_def LIKE '%river%' OR english_def LIKE '%cloud%' OR "
                "english_def LIKE '%wind%' OR english_def LIKE '%season%') "
                "AND han_viet_resonance IN ('high','medium')",
    'body':     "(english_def LIKE '%body%' OR english_def LIKE '%heart%' OR "
                "english_def LIKE '%head%' OR english_def LIKE '%hand%' OR "
                "english_def LIKE '%eye%' OR english_def LIKE '%face%' OR "
                "english_def LIKE '%mind%' OR english_def LIKE '%blood%') "
                "AND han_viet_resonance IN ('high','medium')",
    'city':     "(english_def LIKE '%city%' OR english_def LIKE '%street%' OR "
                "english_def LIKE '%building%' OR english_def LIKE '%road%' OR "
                "english_def LIKE '%house%' OR english_def LIKE '%place%' OR "
                "english_def LIKE '%market%' OR english_def LIKE '%shop%') "
                "AND han_viet_resonance IN ('high','medium')",
    'emotions': "(english_def LIKE '%happy%' OR english_def LIKE '%sad%' OR "
                "english_def LIKE '%angry%' OR english_def LIKE '%love%' OR "
                "english_def LIKE '%fear%' OR english_def LIKE '%hope%' OR "
                "english_def LIKE '%feel%' OR english_def LIKE '%emotion%') "
                "AND han_viet_resonance IN ('high','medium')",
    'time':     "(english_def LIKE '%time%' OR english_def LIKE '%year%' OR "
                "english_def LIKE '%history%' OR english_def LIKE '%period%' OR "
                "english_def LIKE '%century%' OR english_def LIKE '%moment%' OR "
                "english_def LIKE '%hour%') "
                "AND han_viet_resonance IN ('high','medium')",
    'family':   "(english_def LIKE '%family%' OR english_def LIKE '%father%' OR "
                "english_def LIKE '%mother%' OR english_def LIKE '%child%' OR "
                "english_def LIKE '%brother%' OR english_def LIKE '%sister%' OR "
                "english_def LIKE '%society%' OR english_def LIKE '%people%') "
                "AND han_viet_resonance IN ('high','medium')",
    'learning': "(english_def LIKE '%learn%' OR english_def LIKE '%study%' OR "
                "english_def LIKE '%school%' OR english_def LIKE '%knowledge%' OR "
                "english_def LIKE '%teach%' OR english_def LIKE '%book%' OR "
                "english_def LIKE '%language%') "
                "AND han_viet_resonance IN ('high','medium')",
    'travel':   "(english_def LIKE '%travel%' OR english_def LIKE '%transport%' OR "
                "english_def LIKE '%car%' OR english_def LIKE '%train%' OR "
                "english_def LIKE '%trip%' OR english_def LIKE '%airport%' OR "
                "english_def LIKE '%ship%') "
                "AND han_viet_resonance IN ('high','medium')",
    'food':     "(english_def LIKE '%food%' OR english_def LIKE '%eat%' OR "
                "english_def LIKE '%drink%' OR english_def LIKE '%cook%' OR "
                "english_def LIKE '%rice%' OR english_def LIKE '%fruit%' OR "
                "english_def LIKE '%meat%' OR english_def LIKE '%dish%') "
                "AND han_viet_resonance IN ('high','medium')",
    'business': "(english_def LIKE '%business%' OR english_def LIKE '%money%' OR "
                "english_def LIKE '%work%' OR english_def LIKE '%economy%' OR "
                "english_def LIKE '%trade%' OR english_def LIKE '%company%' OR "
                "english_def LIKE '%price%' OR english_def LIKE '%market%') "
                "AND han_viet_resonance IN ('high','medium')",
    'cognates': "is_cognate_anchor = 1",
    'songs':    "hsk_level <= 3 AND han_viet_resonance = 'medium'",
  };

  Future<int> getTopicWordCount(String topicId) async {
    final where = _topicWhere[topicId];
    if (where == null) return 0;
    final row = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM compound_words WHERE $where',
      readsFrom: {_db.compoundWords},
    ).getSingle();
    return row.read<int>('cnt');
  }

  Future<List<CompoundWord>> getTopicWords(String topicId,
      {int offset = 0, int limit = 50}) async {
    final where = _topicWhere[topicId];
    if (where == null) return [];
    final rows = await _db.customSelect('''
      SELECT id, simplified, traditional, pinyin, hangul, han_viet,
             han_viet_resonance, vietnamese_note, english_def,
             hsk_level, frequency_rank, origin_type, is_cognate_anchor, ai_generated
      FROM compound_words
      WHERE $where
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
    // word_id stores character.id — join directly to characters
    final rows = await _db.customSelect('''
      SELECT c.symbol FROM user_collection_words ucw
      JOIN characters c ON c.id = ucw.word_id
      WHERE ucw.collection_id = ?
      ORDER BY ucw.added_at DESC
      LIMIT 20
    ''',
        variables: [const Variable(bookmarksCollectionId)],
        readsFrom: {_db.userCollectionWords, _db.characters}).get();
    return rows.map((r) => r.read<String>('symbol')).toList();
  }
}

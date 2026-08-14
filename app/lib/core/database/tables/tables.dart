import 'package:drift/drift.dart';

// characters
class Characters extends Table {
  TextColumn get id            => text()();
  TextColumn get symbol        => text()();
  TextColumn get pinyin        => text()();
  TextColumn get hangul        => text().nullable()();
  TextColumn get hanViet       => text().withDefault(const Constant(''))();
  TextColumn get englishDef    => text().withDefault(const Constant(''))();
  TextColumn get etymologyStory => text().nullable()();
  TextColumn get decomposition => text().nullable()();
  TextColumn get radical       => text().nullable()();
  IntColumn  get hskLevel      => integer().nullable()();
  TextColumn get jpOnyomi      => text().nullable()();
  IntColumn  get strokeCount   => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// components
class Components extends Table {
  TextColumn get id          => text()();
  TextColumn get symbol      => text()();
  TextColumn get pinyin      => text()();
  TextColumn get hanViet     => text().withDefault(const Constant(''))();
  TextColumn get englishDef  => text().withDefault(const Constant(''))();
  IntColumn  get strokeCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// character_components
class CharacterComponents extends Table {
  TextColumn get characterId    => text().references(Characters, #id)();
  TextColumn get componentId    => text().references(Components, #id)();
  TextColumn get componentType  => text().nullable()();
  IntColumn  get position       => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {characterId, componentId};
}

// compound_words
class CompoundWords extends Table {
  TextColumn get id               => text()();
  TextColumn get simplified       => text()();
  TextColumn get traditional      => text().nullable()();
  TextColumn get pinyin           => text()();
  TextColumn get hangul           => text().nullable()();
  TextColumn get hanViet          => text().withDefault(const Constant(''))();
  TextColumn get hanVietResonance => text().withDefault(const Constant('medium'))();
  TextColumn get vietnameseNote   => text().nullable()();
  TextColumn get englishDef       => text().withDefault(const Constant(''))();
  IntColumn  get hskLevel         => integer().nullable()();
  IntColumn  get frequencyRank    => integer().nullable()();
  TextColumn get originType       => text().withDefault(const Constant('sino_chinese'))();
  IntColumn  get isCognateAnchor  => integer().withDefault(const Constant(0))();
  IntColumn  get aiGenerated      => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// word_characters
class WordCharacters extends Table {
  TextColumn get wordId      => text().references(CompoundWords, #id)();
  TextColumn get characterId => text().references(Characters, #id)();
  IntColumn  get position    => integer()();

  @override
  Set<Column> get primaryKey => {wordId, characterId, position};
}

// user_collections
class UserCollections extends Table {
  TextColumn get id        => text()();
  TextColumn get name      => text()();
  TextColumn get icon      => text().nullable()();
  IntColumn  get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// user_collection_words
class UserCollectionWords extends Table {
  TextColumn get collectionId => text().references(UserCollections, #id)();
  TextColumn get wordId       => text()();
  IntColumn  get addedAt      => integer()();

  @override
  Set<Column> get primaryKey => {collectionId, wordId};
}

// reading_history
class ReadingHistory extends Table {
  TextColumn get id        => text()();
  TextColumn get title     => text()();
  TextColumn get rawText   => text()();
  TextColumn get tokenJson => text()();
  IntColumn  get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ai_cache
class AiCache extends Table {
  TextColumn get query        => text()();
  TextColumn get responseJson => text()();
  IntColumn  get cachedAt     => integer()();

  @override
  Set<Column> get primaryKey => {query};
}

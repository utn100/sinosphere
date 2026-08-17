import 'dart:io';
import 'dart:isolate';
import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

import 'tables/tables.dart';
import 'daos/character_dao.dart';
import 'daos/compound_dao.dart';
import 'daos/collection_dao.dart';
import 'daos/graph_dao.dart';
import 'daos/reader_dao.dart';

export 'tables/tables.dart';
export 'daos/character_dao.dart';
export 'daos/compound_dao.dart';
export 'daos/collection_dao.dart'; // exports CollectionItem too
export 'daos/graph_dao.dart';
export 'daos/reader_dao.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Characters,
  Components,
  CharacterComponents,
  CompoundWords,
  WordCharacters,
  UserCollections,
  UserCollectionWords,
  ReadingHistory,
  AiCache,
  KoreanWords,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(compoundWords, compoundWords.topicTag);
      }
      if (from < 3) {
        await m.addColumn(compoundWords, compoundWords.synonyms);
        await m.addColumn(compoundWords, compoundWords.antonyms);
        await m.addColumn(compoundWords, compoundWords.exampleSentence);
      }
      if (from < 4) {
        await m.addColumn(compoundWords, compoundWords.romaja);
        await m.addColumn(compoundWords, compoundWords.topikLevel);
        await m.addColumn(compoundWords, compoundWords.isSinoKorean);
        await m.addColumn(compoundWords, compoundWords.batchim);
      }
      if (from < 5) {
        await m.addColumn(compoundWords, compoundWords.krVerified);
        await m.addColumn(compoundWords, compoundWords.pos);
        await m.createTable(koreanWords);
      }
      if (from < 6) {
        try {
          await m.addColumn(koreanWords, koreanWords.synonyms);
          await m.addColumn(koreanWords, koreanWords.antonyms);
          await m.addColumn(koreanWords, koreanWords.exampleSentence);
        } catch (_) {}
      }
      if (from < 7) {
        try {
          await m.addColumn(compoundWords, compoundWords.krSynonyms);
          await m.addColumn(compoundWords, compoundWords.krAntonyms);
          await m.addColumn(compoundWords, compoundWords.krExample);
        } catch (_) {}
      }
      if (from < 8) {
        try {
          await m.addColumn(compoundWords, compoundWords.topikInSource);
          // Populate from existing topik_level data after column is added
          await m.database.customStatement('''
            UPDATE compound_words
            SET topik_in_source = 1
            WHERE topik_level IS NOT NULL
              AND kr_verified = 1
              AND LENGTH(hangul) >= 2
          ''');
        } catch (_) {}
      }
    },
  );

  late final CharacterDao  characterDao  = CharacterDao(this);
  late final CompoundDao   compoundDao   = CompoundDao(this);
  late final CollectionDao collectionDao = CollectionDao(this);
  late final GraphDao      graphDao      = GraphDao(this);
  late final ReaderDao     readerDao     = ReaderDao(this);

  Future<String?> getCachedAiResponse(String query) async {
    final row = await (select(aiCache)..where((c) => c.query.equals(query)))
        .getSingleOrNull();
    return row?.responseJson;
  }

  Future<void> cacheAiResponse(String query, String responseJson) async {
    await into(aiCache).insertOnConflictUpdate(AiCacheCompanion(
      query: Value(query),
      responseJson: Value(responseJson),
      cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }
}

Future<AppDatabase> openDatabase() async {
  final dbDir  = await getDatabasesPath();
  final dbPath = join(dbDir, 'sinosphere.db');

  if (!await File(dbPath).exists()) {
    // Load asset bytes on main isolate (rootBundle requires it), then
    // write to disk on a background isolate to avoid blocking the UI.
    final data  = await rootBundle.load('assets/sinosphere.db');
    final bytes = data.buffer.asUint8List();
    await Isolate.run(() async {
      await File(dbPath).writeAsBytes(bytes, flush: true);
    });
  }

  return AppDatabase(SqfliteQueryExecutor.inDatabaseFolder(path: 'sinosphere.db'));
}

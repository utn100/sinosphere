import 'package:drift/drift.dart';
import '../database.dart';

class ReaderDao {
  final AppDatabase _db;
  ReaderDao(this._db);

  Future<void> saveHistory({
    required String id,
    required String title,
    required String rawText,
    required String tokenJson,
  }) async {
    await _db.into(_db.readingHistory).insertOnConflictUpdate(
      ReadingHistoryCompanion(
        id: Value(id),
        title: Value(title),
        rawText: Value(rawText),
        tokenJson: Value(tokenJson),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<List<ReadingHistoryData>> getHistory({int limit = 30}) =>
      (_db.select(_db.readingHistory)
            ..orderBy([(h) => OrderingTerm.desc(h.createdAt)])
            ..limit(limit))
          .get();

  Future<void> deleteHistory(String id) =>
      (_db.delete(_db.readingHistory)..where((h) => h.id.equals(id))).go();
}

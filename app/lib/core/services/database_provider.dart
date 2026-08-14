import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

// Single database instance for the whole app
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database must be overridden in ProviderScope');
});

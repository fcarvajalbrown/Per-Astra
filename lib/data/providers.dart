/// Core data-layer providers (ADR-001).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../content/content_repository.dart';
import 'database.dart';

part 'providers.g.dart';

/// The single app-wide Drift database. Kept alive for the app's lifetime and
/// closed when the provider is disposed.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

/// Repository for bundled lesson/module content.
@Riverpod(keepAlive: true)
ContentRepository contentRepository(Ref ref) => ContentRepository();

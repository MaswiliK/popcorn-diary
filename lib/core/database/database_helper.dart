import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the local SQLite connection.
///
/// Local-first principle: the diary must work fully offline. This is the
/// single source of truth for the user's personal collection — TMDB only
/// enriches it (see services/movie_metadata_provider.dart).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'popcorn_diary.db';
  static const _dbVersion = 2;

  static const tableMovieEntries = 'movie_entries';
  static const tableTmdbCache = 'tmdb_metadata_cache';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createMovieEntriesTable(db);
    await _createTmdbCacheTable(db);
  }

  /// Runs when an existing (already-installed) database is older than
  /// [_dbVersion]. Each `if` is additive and independent so a user
  /// upgrading across multiple versions at once picks up every step.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTmdbCacheTable(db);
    }
  }

  Future<void> _createMovieEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableMovieEntries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tmdb_id INTEGER,
        title TEXT NOT NULL,
        release_date TEXT,
        runtime_minutes INTEGER,
        overview TEXT,
        poster_path TEXT,
        custom_poster_path TEXT,
        backdrop_path TEXT,
        genres TEXT,
        director TEXT,
        cast TEXT,
        rating REAL,
        my_take TEXT,
        wtf_moment TEXT,
        watched_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_movie_entries_watched_at ON $tableMovieEntries (watched_at)',
    );
    await db.execute(
      'CREATE INDEX idx_movie_entries_tmdb_id ON $tableMovieEntries (tmdb_id)',
    );
  }

  /// Persistent cache of TMDB `getDetails()` responses, keyed by TMDB's
  /// own movie id. Added in schema v2 — see CachedMovieMetadataProvider,
  /// which reads/writes this table so metadata survives app restarts
  /// instead of refetching every cold start (Phase 2 polish item).
  Future<void> _createTmdbCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableTmdbCache (
        tmdb_id INTEGER PRIMARY KEY,
        payload TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

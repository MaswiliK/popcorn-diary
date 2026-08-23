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
  static const _dbVersion = 1;

  static const tableMovieEntries = 'movie_entries';

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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

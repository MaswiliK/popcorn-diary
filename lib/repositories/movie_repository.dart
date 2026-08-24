import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/movie_entry.dart';

/// The diary's source of truth. All reads/writes to the user's personal
/// collection go through here — never directly through the metadata
/// provider. See "TMDB supplies movie information. Popcorn Diary owns
/// the memory."
class MovieRepository {
  MovieRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  Future<int> addEntry(MovieEntry entry) async {
    final db = await _databaseHelper.database;
    return db.insert(
      DatabaseHelper.tableMovieEntries,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateEntry(MovieEntry entry) async {
    assert(entry.id != null, 'Cannot update an entry without an id');
    final db = await _databaseHelper.database;
    return db.update(
      DatabaseHelper.tableMovieEntries,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await _databaseHelper.database;
    return db.delete(
      DatabaseHelper.tableMovieEntries,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<MovieEntry?> getEntry(int id) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableMovieEntries,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MovieEntry.fromMap(rows.first);
  }

  /// All entries, most recently watched first — the base list the Diary
  /// screen groups into weeks.
  Future<List<MovieEntry>> getAllEntries() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableMovieEntries,
      orderBy: 'watched_at DESC',
    );
    return rows.map(MovieEntry.fromMap).toList();
  }

  Future<List<MovieEntry>> searchEntries(String query) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableMovieEntries,
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'watched_at DESC',
    );
    return rows.map(MovieEntry.fromMap).toList();
  }

  Future<int> countEntries() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM ${DatabaseHelper.tableMovieEntries}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// How many diary entries still reference a given TMDB movie id. Used
  /// before evicting that movie's cached metadata on delete — a rewatch
  /// (same movie, multiple entries) should keep the cache until the
  /// *last* referencing entry is gone, not the first.
  Future<int> countEntriesWithTmdbId(int tmdbId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DatabaseHelper.tableMovieEntries} WHERE tmdb_id = ?',
      [tmdbId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

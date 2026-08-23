import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../services/movie_metadata_provider.dart';

/// Reads/writes cached [MovieMetadata] to SQLite, keyed by the provider's
/// external (TMDB) id. Backs [CachedMovieMetadataProvider] so a movie's
/// details only need to be fetched from TMDB once, ever — not once per
/// app session.
class MetadataCacheRepository {
  MetadataCacheRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  /// Cached entries older than this are treated as a miss and refetched.
  /// Movie metadata (runtime, cast, genres) essentially never changes
  /// after release, so this is generous — it exists mainly so a bad/
  /// incomplete early fetch doesn't stick around forever.
  static const maxAge = Duration(days: 30);

  Future<MovieMetadata?> getCached(int externalId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableTmdbCache,
      where: 'tmdb_id = ?',
      whereArgs: [externalId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final cachedAt = DateTime.tryParse(row['cached_at'] as String? ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > maxAge) {
      return null;
    }

    try {
      final json = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return _fromJson(json);
    } catch (_) {
      // Corrupt/unreadable cache row — treat as a miss rather than crash.
      return null;
    }
  }

  Future<void> putCached(MovieMetadata metadata) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableTmdbCache,
      {
        'tmdb_id': metadata.externalId,
        'payload': jsonEncode(_toJson(metadata)),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> count() async {
    final db = await _databaseHelper.database;
    final result = await db
        .rawQuery('SELECT COUNT(*) AS c FROM ${DatabaseHelper.tableTmdbCache}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clear() async {
    final db = await _databaseHelper.database;
    await db.delete(DatabaseHelper.tableTmdbCache);
  }

  Map<String, dynamic> _toJson(MovieMetadata m) => {
        'externalId': m.externalId,
        'title': m.title,
        'releaseDate': m.releaseDate?.toIso8601String(),
        'runtimeMinutes': m.runtimeMinutes,
        'overview': m.overview,
        'posterPaths': m.posterPaths,
        'backdropPath': m.backdropPath,
        'genres': m.genres,
        'director': m.director,
        'cast': m.cast,
      };

  MovieMetadata _fromJson(Map<String, dynamic> json) => MovieMetadata(
        externalId: json['externalId'] as int,
        title: json['title'] as String? ?? '',
        releaseDate: json['releaseDate'] != null
            ? DateTime.tryParse(json['releaseDate'] as String)
            : null,
        runtimeMinutes: json['runtimeMinutes'] as int?,
        overview: json['overview'] as String?,
        posterPaths:
            (json['posterPaths'] as List<dynamic>? ?? []).cast<String>(),
        backdropPath: json['backdropPath'] as String?,
        genres: (json['genres'] as List<dynamic>? ?? []).cast<String>(),
        director: json['director'] as String?,
        cast: (json['cast'] as List<dynamic>? ?? []).cast<String>(),
      );
}

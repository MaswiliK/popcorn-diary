/// The core entity of Popcorn Diary.
///
/// Architectural principle: TMDB supplies movie information,
/// Popcorn Diary owns the memory. Every field here lives in SQLite,
/// so the diary works fully offline once a movie has been saved.
class MovieEntry {
  final int? id;

  // Identity / linkage to metadata provider (kept abstract — see
  // services/movie_metadata_provider.dart)
  final int? tmdbId;
  final String title;

  // Imported metadata (secondary — supports the memory, doesn't lead it)
  final DateTime? releaseDate;
  final int? runtimeMinutes;
  final String? overview;
  final String? posterPath;
  final String? customPosterPath; // user-uploaded / user-selected override
  final String? backdropPath;
  final List<String> genres;
  final String? director;
  final List<String> cast;

  // Personal — this is the actual content of the diary
  final double? rating; // 0.0 - 10.0, half-point steps (matches "8.5/10")
  final String? myTake;
  final String? wtfMoment;
  final DateTime watchedAt;

  // Bookkeeping
  final DateTime createdAt;
  final DateTime updatedAt;

  const MovieEntry({
    this.id,
    this.tmdbId,
    required this.title,
    this.releaseDate,
    this.runtimeMinutes,
    this.overview,
    this.posterPath,
    this.customPosterPath,
    this.backdropPath,
    this.genres = const [],
    this.director,
    this.cast = const [],
    this.rating,
    this.myTake,
    this.wtfMoment,
    required this.watchedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The poster actually shown to the user: a custom override always wins,
  /// per "Editable Posters" in the spec.
  String? get effectivePosterPath => customPosterPath ?? posterPath;

  /// ISO week grouping key, e.g. "2026-W18", used to bucket entries into
  /// the "WEEK 18" sections seen in the Diary screen.
  String get weekKey {
    final date = watchedAt;
    final thursday = date.add(Duration(days: 3 - ((date.weekday + 6) % 7)));
    final firstDayOfYear = DateTime(thursday.year, 1, 1);
    final weekNumber =
        ((thursday.difference(firstDayOfYear).inDays) / 7).floor() + 1;
    return '${thursday.year}-W$weekNumber';
  }

  MovieEntry copyWith({
    int? id,
    int? tmdbId,
    String? title,
    DateTime? releaseDate,
    int? runtimeMinutes,
    String? overview,
    String? posterPath,
    String? customPosterPath,
    String? backdropPath,
    List<String>? genres,
    String? director,
    List<String>? cast,
    double? rating,
    String? myTake,
    String? wtfMoment,
    DateTime? watchedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MovieEntry(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      releaseDate: releaseDate ?? this.releaseDate,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      customPosterPath: customPosterPath ?? this.customPosterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      genres: genres ?? this.genres,
      director: director ?? this.director,
      cast: cast ?? this.cast,
      rating: rating ?? this.rating,
      myTake: myTake ?? this.myTake,
      wtfMoment: wtfMoment ?? this.wtfMoment,
      watchedAt: watchedAt ?? this.watchedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MovieEntry.fromMap(Map<String, dynamic> map) {
    return MovieEntry(
      id: map['id'] as int?,
      tmdbId: map['tmdb_id'] as int?,
      title: map['title'] as String,
      releaseDate: map['release_date'] != null
          ? DateTime.tryParse(map['release_date'] as String)
          : null,
      runtimeMinutes: map['runtime_minutes'] as int?,
      overview: map['overview'] as String?,
      posterPath: map['poster_path'] as String?,
      customPosterPath: map['custom_poster_path'] as String?,
      backdropPath: map['backdrop_path'] as String?,
      genres: _decodeList(map['genres'] as String?),
      director: map['director'] as String?,
      cast: _decodeList(map['cast'] as String?),
      rating: (map['rating'] as num?)?.toDouble(),
      myTake: map['my_take'] as String?,
      wtfMoment: map['wtf_moment'] as String?,
      watchedAt: DateTime.parse(map['watched_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tmdb_id': tmdbId,
      'title': title,
      'release_date': releaseDate?.toIso8601String(),
      'runtime_minutes': runtimeMinutes,
      'overview': overview,
      'poster_path': posterPath,
      'custom_poster_path': customPosterPath,
      'backdrop_path': backdropPath,
      'genres': _encodeList(genres),
      'director': director,
      'cast': _encodeList(cast),
      'rating': rating,
      'my_take': myTake,
      'wtf_moment': wtfMoment,
      'watched_at': watchedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static String _encodeList(List<String> items) => items.join('|');

  static List<String> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw.split('|');
  }
}

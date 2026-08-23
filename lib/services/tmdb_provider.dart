import 'dart:convert';
import 'package:http/http.dart' as http;

import 'movie_metadata_provider.dart';

/// TMDB implementation of [MovieMetadataProvider].
///
/// Kept behind the abstract interface so the rest of the app never touches
/// TMDB's response shape directly. Requires a TMDB API read access token —
/// see https://www.themoviedb.org/settings/api.
///
/// This is Phase 2 groundwork: wired up but not yet called from the UI in
/// the Phase 0 foundation.
class TMDBProvider implements MovieMetadataProvider {
  TMDBProvider({required this.apiReadAccessToken, http.Client? client})
      : _client = client ?? http.Client();

  final String apiReadAccessToken;
  final http.Client _client;

  static const _baseUrl = 'https://api.themoviedb.org/3';
  static const _defaultPosterSize = 'w500';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiReadAccessToken',
        'accept': 'application/json',
      };

  @override
  Future<List<MovieSearchResult>> search(String query) async {
    final uri = Uri.parse('$_baseUrl/search/movie').replace(queryParameters: {
      'query': query,
      'include_adult': 'false',
    });
    final response = await _client.get(uri, headers: _headers);
    _checkOk(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? []);

    return results.map((raw) {
      final map = raw as Map<String, dynamic>;
      return MovieSearchResult(
        externalId: map['id'] as int,
        title: map['title'] as String? ?? '',
        releaseDate: _parseDate(map['release_date'] as String?),
        posterPath: map['poster_path'] as String?,
      );
    }).toList();
  }

  @override
  Future<MovieMetadata> getDetails(int externalId) async {
    final uri = Uri.parse('$_baseUrl/movie/$externalId').replace(
      queryParameters: {'append_to_response': 'credits,images'},
    );
    final response = await _client.get(uri, headers: _headers);
    _checkOk(response);

    final map = jsonDecode(response.body) as Map<String, dynamic>;

    final credits = map['credits'] as Map<String, dynamic>? ?? {};
    final crew = (credits['crew'] as List<dynamic>? ?? []);
    final castList = (credits['cast'] as List<dynamic>? ?? []);
    final director = crew
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (c) => c['job'] == 'Director',
          orElse: () => const {},
        )['name'] as String?;

    final images = map['images'] as Map<String, dynamic>? ?? {};
    final posters = (images['posters'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((p) => p['file_path'] as String)
        .toList();
    final mainPoster = map['poster_path'] as String?;
    final posterPaths = [
      if (mainPoster != null) mainPoster,
      ...posters.where((p) => p != mainPoster),
    ];

    return MovieMetadata(
      externalId: map['id'] as int,
      title: map['title'] as String? ?? '',
      releaseDate: _parseDate(map['release_date'] as String?),
      runtimeMinutes: map['runtime'] as int?,
      overview: map['overview'] as String?,
      posterPaths: posterPaths,
      backdropPath: map['backdrop_path'] as String?,
      genres: (map['genres'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map((g) => g['name'] as String)
          .toList(),
      director: director,
      cast: castList
          .cast<Map<String, dynamic>>()
          .take(10)
          .map((c) => c['name'] as String)
          .toList(),
    );
  }

  @override
  String imageUrl(String path, {String size = _defaultPosterSize}) {
    return 'https://image.tmdb.org/t/p/$size$path';
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  void _checkOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MovieMetadataException(
        'TMDB request failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}

class MovieMetadataException implements Exception {
  final String message;
  MovieMetadataException(this.message);

  @override
  String toString() => 'MovieMetadataException: $message';
}

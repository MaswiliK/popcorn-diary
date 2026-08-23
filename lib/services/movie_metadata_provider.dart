/// A lightweight, provider-agnostic search result.
class MovieSearchResult {
  final int externalId;
  final String title;
  final DateTime? releaseDate;
  final String? posterPath;

  const MovieSearchResult({
    required this.externalId,
    required this.title,
    this.releaseDate,
    this.posterPath,
  });
}

/// Full metadata for a single movie, as returned by a provider.
class MovieMetadata {
  final int externalId;
  final String title;
  final DateTime? releaseDate;
  final int? runtimeMinutes;
  final String? overview;
  final List<String> posterPaths;
  final String? backdropPath;
  final List<String> genres;
  final String? director;
  final List<String> cast;

  const MovieMetadata({
    required this.externalId,
    required this.title,
    this.releaseDate,
    this.runtimeMinutes,
    this.overview,
    this.posterPaths = const [],
    this.backdropPath,
    this.genres = const [],
    this.director,
    this.cast = const [],
  });
}

/// Abstraction over any movie metadata source.
///
/// The UI and repositories must depend on this interface, never on a
/// concrete provider's response shape, so the provider can be swapped
/// later (see "Provider abstraction" in the product spec):
///
///   MovieMetadataProvider
///           |
///           +-- TMDBProvider
abstract class MovieMetadataProvider {
  Future<List<MovieSearchResult>> search(String query);
  Future<MovieMetadata> getDetails(int externalId);

  /// Full image URL for a given provider-relative path/size.
  String imageUrl(String path, {String size});
}

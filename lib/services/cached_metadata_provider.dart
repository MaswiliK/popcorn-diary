import '../repositories/metadata_cache_repository.dart';
import 'movie_metadata_provider.dart';

/// Wraps another [MovieMetadataProvider] and persists `getDetails()`
/// responses to SQLite via [MetadataCacheRepository], so a movie's
/// details are fetched from the network at most once per [maxAge]
/// window — see the cache repository for that policy.
///
/// Search is intentionally NOT cached: query strings vary too much for
/// caching to pay off, and search results change less predictably than
/// a single movie's fixed metadata.
///
/// This is a decorator, not a different implementation — the rest of
/// the app still depends only on [MovieMetadataProvider], unaware that
/// caching happens at all.
class CachedMovieMetadataProvider implements MovieMetadataProvider {
  CachedMovieMetadataProvider({
    required MovieMetadataProvider inner,
    required MetadataCacheRepository cache,
  })  : _inner = inner,
        _cache = cache;

  final MovieMetadataProvider _inner;
  final MetadataCacheRepository _cache;

  /// The provider being wrapped — exposed so screens that need to know
  /// provider-specific details (e.g. "is a TMDB token configured?") can
  /// still reach it without the cache layer getting in the way.
  MovieMetadataProvider get inner => _inner;

  @override
  Future<List<MovieSearchResult>> search(String query) => _inner.search(query);

  @override
  Future<MovieMetadata> getDetails(int externalId) async {
    final cached = await _cache.getCached(externalId);
    if (cached != null) return cached;

    final fresh = await _inner.getDetails(externalId);
    await _cache.putCached(fresh);
    return fresh;
  }

  @override
  String imageUrl(String path, {String size = 'w500'}) =>
      _inner.imageUrl(path, size: size);
}

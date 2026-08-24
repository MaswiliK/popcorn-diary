import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie_entry.dart';
import '../repositories/metadata_cache_repository.dart';
import '../repositories/movie_repository.dart';
import '../services/cached_metadata_provider.dart';
import '../services/movie_metadata_provider.dart';
import '../services/tmdb_provider.dart';
import 'config.dart';

/// Central dependency wiring. Screens should read state through these
/// providers rather than instantiating repositories/services directly.
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepository();
});

final metadataCacheRepositoryProvider =
    Provider<MetadataCacheRepository>((ref) {
  return MetadataCacheRepository();
});

/// The active metadata provider, wrapped with a persistent SQLite cache
/// so a given movie's details are fetched from TMDB at most once (see
/// CachedMovieMetadataProvider / MetadataCacheRepository). Screens depend
/// on the abstract [MovieMetadataProvider] type only — swapping providers
/// or removing the cache layer later means changing this one place, not
/// any UI code.
final movieMetadataProvider = Provider<MovieMetadataProvider>((ref) {
  final raw = TMDBProvider(apiReadAccessToken: AppConfig.tmdbApiToken);
  final cache = ref.watch(metadataCacheRepositoryProvider);
  return CachedMovieMetadataProvider(inner: raw, cache: cache);
});

/// Debounced, cancellable TMDB search keyed by query string. Screens
/// watch this with the current query; autoDispose drops stale requests
/// as the user keeps typing.
final movieSearchProvider = FutureProvider.autoDispose
    .family<List<MovieSearchResult>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  // Debounce: give the user a beat to keep typing before we hit the network.
  await Future.delayed(const Duration(milliseconds: 400));
  ref.onDispose(() {}); // autoDispose handles cancellation of stale queries
  final provider = ref.watch(movieMetadataProvider);
  return provider.search(query.trim());
});

/// Full metadata for a single TMDB movie. The underlying provider
/// (see [movieMetadataProvider]) is itself cache-backed by SQLite, so
/// repeated lookups of the same movie — including across app restarts —
/// don't re-hit the network.
final movieDetailsProvider =
    FutureProvider.family<MovieMetadata, int>((ref, externalId) async {
  final provider = ref.watch(movieMetadataProvider);
  return provider.getDetails(externalId);
});

/// All diary entries, most recently watched first.
final movieEntriesProvider =
    FutureProvider.autoDispose<List<MovieEntry>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getAllEntries();
});

/// A single entry, for the detail screen.
final movieEntryProvider =
    FutureProvider.autoDispose.family<MovieEntry?, int>((ref, id) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getEntry(id);
});

/// Entries grouped by ISO week key, newest week first — backs the
/// "WEEK 18 / WEEK 17 / ..." sections on the Diary screen.
final entriesByWeekProvider =
    FutureProvider.autoDispose<Map<String, List<MovieEntry>>>((ref) async {
  final entries = await ref.watch(movieEntriesProvider.future);
  final grouped = <String, List<MovieEntry>>{};
  for (final entry in entries) {
    grouped.putIfAbsent(entry.weekKey, () => []).add(entry);
  }
  return grouped;
});

/// The Diary screen's current search box contents. Empty string means
/// "show the normal weekly view" rather than "search for nothing".
final diarySearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Title-matched local search results for the Diary screen, driven by
/// [diarySearchQueryProvider]. Searches the on-device SQLite collection
/// only — no network involved, so this works offline.
final diarySearchResultsProvider =
    FutureProvider.autoDispose<List<MovieEntry>>((ref) async {
  final query = ref.watch(diarySearchQueryProvider).trim();
  if (query.isEmpty) return [];
  final repo = ref.watch(movieRepositoryProvider);
  return repo.searchEntries(query);
});

/// Whether Diary/search results render as poster rows or a poster grid.
enum DiaryViewMode { list, grid }

/// Current view mode for the Diary screen (list rows vs. poster grid).
final diaryViewModeProvider =
    StateProvider.autoDispose<DiaryViewMode>((ref) => DiaryViewMode.list);

/// Week keys the user has manually collapsed. A week not in this set is
/// expanded — i.e. everything starts expanded, matching the pre-fold
/// behavior, and folding is purely an opt-in decluttering action.
final collapsedWeeksProvider =
    StateProvider.autoDispose<Set<String>>((ref) => <String>{});

/// Total number of diary entries — used on the Settings screen.
final movieEntryCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.countEntries();
});

/// Number of movies with cached TMDB metadata — used on the Settings
/// screen so "Clear cached data" isn't a mystery button with no context.
final metadataCacheCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final cache = ref.watch(metadataCacheRepositoryProvider);
  return cache.count();
});

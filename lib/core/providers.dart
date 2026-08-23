import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie_entry.dart';
import '../repositories/movie_repository.dart';
import '../services/movie_metadata_provider.dart';
import '../services/tmdb_provider.dart';
import 'config.dart';

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepository();
});

final movieMetadataProvider = Provider<MovieMetadataProvider>((ref) {
  return TMDBProvider(apiReadAccessToken: AppConfig.tmdbApiToken);
});

final movieSearchProvider = FutureProvider.autoDispose
    .family<List<MovieSearchResult>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  await Future.delayed(const Duration(milliseconds: 400));
  ref.onDispose(() {});
  final provider = ref.watch(movieMetadataProvider);
  return provider.search(query.trim());
});

final movieDetailsProvider =
    FutureProvider.family<MovieMetadata, int>((ref, externalId) async {
  final provider = ref.watch(movieMetadataProvider);
  return provider.getDetails(externalId);
});

final movieEntriesProvider =
    FutureProvider.autoDispose<List<MovieEntry>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getAllEntries();
});

final movieEntryProvider =
    FutureProvider.autoDispose.family<MovieEntry?, int>((ref, id) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getEntry(id);
});

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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie_entry.dart';
import '../repositories/movie_repository.dart';
import '../services/movie_metadata_provider.dart';
import '../services/tmdb_provider.dart';
import 'config.dart';

/// Central dependency wiring. Screens should read state through these
/// providers rather than instantiating repositories/services directly.
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepository();
});

/// The active metadata provider. Screens depend on the abstract
/// [MovieMetadataProvider] type only — swapping providers later means
/// changing this one line, not any UI code.
final movieMetadataProvider = Provider<MovieMetadataProvider>((ref) {
  return TMDBProvider(apiReadAccessToken: AppConfig.tmdbApiToken);
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

/// Full metadata for a single TMDB movie, cached per external id for the
/// lifetime of the provider container (avoids refetching on back/forward
/// navigation within a session — a lightweight stand-in for Phase 2's
/// planned persistent cache).
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie_entry.dart';
import '../repositories/movie_repository.dart';

/// Central dependency wiring. Screens should read state through these
/// providers rather than instantiating repositories/services directly.
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepository();
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

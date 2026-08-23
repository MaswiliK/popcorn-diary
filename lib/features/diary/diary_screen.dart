import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/movie_entry.dart';
import '../../widgets/poster_thumbnail.dart';

/// The heart of Popcorn Diary. Preserves the user's existing mental model
/// of weekly movie notes — see "Diary" in the product spec.
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(diarySearchQueryProvider.notifier).state = value;
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(diarySearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(diarySearchQueryProvider);
    final isSearching = query.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Movie Journal',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Your cinematic journey.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search movies...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textTertiary),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isSearching ? const _SearchResults() : const _WeeklyView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyView extends ConsumerWidget {
  const _WeeklyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeksAsync = ref.watch(entriesByWeekProvider);

    return weeksAsync.when(
      data: (weeksMap) {
        if (weeksMap.isEmpty) {
          return const _EmptyDiary();
        }
        final sortedKeys = weeksMap.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        return ListView.separated(
          itemCount: sortedKeys.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final key = sortedKeys[index];
            final entries = weeksMap[key]!;
            return _WeekSection(weekKey: key, entries: entries);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Could not load your diary.\n$err',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}

/// Flat, title-matched results from the local SQLite collection — no
/// network involved, so this works fully offline. Backed by
/// [diarySearchResultsProvider] in core/providers.dart.
class _SearchResults extends ConsumerWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(diarySearchResultsProvider);

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Text('No movies match your search.',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _MovieRow(entry: results[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Search failed.\n$err',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}

class _WeekSection extends StatelessWidget {
  const _WeekSection({required this.weekKey, required this.entries});

  final String weekKey;
  final List<MovieEntry> entries;

  @override
  Widget build(BuildContext context) {
    final parts = weekKey.split('-W');
    final weekNumber = parts.length > 1 ? int.tryParse(parts[1]) : null;
    final weekLabel =
        'WEEK ${weekNumber ?? (parts.length > 1 ? parts[1] : '')}';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined,
                color: AppColors.textSecondary),
            title: Text(weekLabel,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.badge,
              child: Text('${entries.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ),
          const Divider(height: 1),
          ...entries.map((entry) => _MovieRow(entry: entry)),
        ],
      ),
    );
  }
}

class _MovieRow extends StatelessWidget {
  const _MovieRow({required this.entry});

  final MovieEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: PosterThumbnail(
          imageUrl: entry.effectivePosterPath, width: 40, height: 56),
      title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(DateFormat('dd/MM').format(entry.watchedAt)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: () => context.push('/diary/movie/${entry.id}'),
    );
  }
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_movies_outlined,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('No movies yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add the first movie to your diary.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

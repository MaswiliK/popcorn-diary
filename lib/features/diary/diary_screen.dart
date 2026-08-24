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
    final viewMode = ref.watch(diaryViewModeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Movie Journal',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text('Your cinematic journey.',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const _ViewModeToggle(),
              ],
            ),
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
              child: isSearching
                  ? _SearchResults(viewMode: viewMode)
                  : _WeeklyView(viewMode: viewMode),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewModeToggle extends ConsumerWidget {
  const _ViewModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(diaryViewModeProvider);

    Widget button(IconData icon, DiaryViewMode target) {
      final selected = mode == target;
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => ref.read(diaryViewModeProvider.notifier).state = target,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18,
              color: selected ? Colors.white : AppColors.textSecondary),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.view_list_outlined, DiaryViewMode.list),
          button(Icons.grid_view_outlined, DiaryViewMode.grid),
        ],
      ),
    );
  }
}

class _WeeklyView extends ConsumerWidget {
  const _WeeklyView({required this.viewMode});

  final DiaryViewMode viewMode;

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
            return _WeekSection(
              key: ValueKey(key),
              weekKey: key,
              entries: entries,
              viewMode: viewMode,
            );
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
  const _SearchResults({required this.viewMode});

  final DiaryViewMode viewMode;

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
        return SingleChildScrollView(
          child: viewMode == DiaryViewMode.grid
              ? _PosterGrid(entries: results)
              : Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final entry in results) _MovieRow(entry: entry),
                    ],
                  ),
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

/// A single foldable week section. Tapping the header (or its chevron)
/// collapses/expands the entries — state lives in [collapsedWeeksProvider]
/// so it survives scrolling the list, unlike widget-local state would.
class _WeekSection extends ConsumerWidget {
  const _WeekSection({
    super.key,
    required this.weekKey,
    required this.entries,
    required this.viewMode,
  });

  final String weekKey;
  final List<MovieEntry> entries;
  final DiaryViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(collapsedWeeksProvider).contains(weekKey);
    final parts = weekKey.split('-W');
    final weekNumber = parts.length > 1 ? int.tryParse(parts[1]) : null;
    final weekLabel =
        'WEEK ${weekNumber ?? (parts.length > 1 ? parts[1] : '')}';

    void toggle() {
      final current = {...ref.read(collapsedWeeksProvider)};
      if (collapsed) {
        current.remove(weekKey);
      } else {
        current.add(weekKey);
      }
      ref.read(collapsedWeeksProvider.notifier).state = current;
    }

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: toggle,
            child: ListTile(
              leading: const Icon(Icons.calendar_today_outlined,
                  color: AppColors.textSecondary),
              title: Text(weekLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.badge,
                    child: Text('${entries.length}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: collapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: collapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                if (viewMode == DiaryViewMode.grid)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _PosterGrid(entries: entries),
                  )
                else
                  for (final entry in entries) _MovieRow(entry: entry),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared poster-grid layout used in both grid view mode and search
/// results grid view. Not independently scrollable — it's meant to sit
/// inside an already-scrolling parent.
class _PosterGrid extends StatelessWidget {
  const _PosterGrid({required this.entries});

  final List<MovieEntry> entries;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) => _MoviePosterTile(entry: entries[index]),
    );
  }
}

class _MoviePosterTile extends StatelessWidget {
  const _MoviePosterTile({required this.entry});

  final MovieEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/diary/movie/${entry.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: PosterThumbnail(
                imageUrl: entry.effectivePosterPath,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
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

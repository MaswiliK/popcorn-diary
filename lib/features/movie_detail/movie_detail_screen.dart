import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/movie_entry.dart';
import '../../widgets/poster_thumbnail.dart';

/// Poster-led detail screen. Personal content (My Take, WTF Moment) is
/// shown before external metadata — per "Movie Detail Screen" in the spec.
class MovieDetailScreen extends ConsumerWidget {
  const MovieDetailScreen({super.key, required this.entryId});

  final int entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(movieEntryProvider(entryId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          entryAsync.maybeWhen(
            data: (entry) => entry == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: () async {
                      await context.push('/edit-movie', extra: entry);
                      // The edit screen invalidates the providers itself;
                      // this just makes sure this screen reflects it too.
                      ref.invalidate(movieEntryProvider(entryId));
                    },
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: entryAsync.when(
        data: (entry) {
          if (entry == null) {
            return const Center(child: Text('Movie not found.'));
          }
          return _DetailBody(entry: entry);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('$err')),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.entry});

  final MovieEntry entry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: PosterThumbnail(
              imageUrl: entry.effectivePosterPath,
              width: 180,
              height: 260,
              borderRadius: 14,
            ),
          ),
          const SizedBox(height: 20),
          Text(entry.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.star, size: 18),
              const SizedBox(width: 4),
              Text('${entry.rating?.toStringAsFixed(1) ?? '–'}/10'),
              const SizedBox(width: 12),
              Text(DateFormat('dd/MM/yyyy').format(entry.watchedAt),
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          if (entry.myTake != null && entry.myTake!.isNotEmpty)
            _NoteCard(title: 'My Take', body: entry.myTake!),
          if (entry.wtfMoment != null && entry.wtfMoment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _NoteCard(title: 'WTF Moment', body: entry.wtfMoment!, icon: '💀'),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          if (entry.releaseDate != null || entry.runtimeMinutes != null)
            Wrap(
              spacing: 12,
              children: [
                if (entry.releaseDate != null)
                  Text('${entry.releaseDate!.year}'),
                if (entry.runtimeMinutes != null)
                  Text(
                      '${entry.runtimeMinutes! ~/ 60}h ${entry.runtimeMinutes! % 60}m'),
                if (entry.genres.isNotEmpty) Text(entry.genres.join(' · ')),
              ],
            ),
          if (entry.director != null) ...[
            const SizedBox(height: 16),
            Text('Director', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(entry.director!,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
          if (entry.overview != null && entry.overview!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Overview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(entry.overview!,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.title, required this.body, this.icon});

  final String title;
  final String body;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon != null ? '$icon $title' : title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

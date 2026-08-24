import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../services/movie_metadata_provider.dart';
import '../../widgets/poster_thumbnail.dart';
import '../../core/network_error.dart';

/// Search TMDB and return the chosen [MovieSearchResult] to the caller via
/// `Navigator.pop(result)`. The Add Movie screen uses this to autofill its
/// form — see "adding a movie becomes fast and enjoyable" (Phase 2 goal).
class TmdbSearchScreen extends ConsumerStatefulWidget {
  const TmdbSearchScreen({super.key});

  @override
  ConsumerState<TmdbSearchScreen> createState() => _TmdbSearchScreenState();
}

class _TmdbSearchScreenState extends ConsumerState<TmdbSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = AppConfig.hasTmdbToken;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search TMDB'),
        leading: const CloseButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search movie title...',
                prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 16),
            if (!hasToken)
              const _NoTokenNotice()
            else
              Expanded(child: _ResultsList(query: _query)),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.trim().length < 2) {
      return const Center(
        child: Text('Keep typing to search…',
            style: TextStyle(color: AppColors.textTertiary)),
      );
    }

    final resultsAsync = ref.watch(movieSearchProvider(query));

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Text('No matches found.',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        final provider = ref.read(movieMetadataProvider);
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final r = results[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PosterThumbnail(
                imageUrl: r.posterPath == null
                    ? null
                    : provider.imageUrl(r.posterPath!, size: 'w185'),
                width: 44,
                height: 64,
              ),
              title: Text(r.title),
              subtitle: r.releaseDate != null
                  ? Text(DateFormat('yyyy').format(r.releaseDate!))
                  : null,
              onTap: () => Navigator.of(context).pop(r),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined,
                  size: 36, color: AppColors.textTertiary),
              const SizedBox(height: 10),
              Text(
                friendlyMetadataErrorMessage(err),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoTokenNotice extends StatelessWidget {
  const _NoTokenNotice();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.key_off_outlined,
                  size: 40, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text('TMDB search is not configured',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Run the app with a TMDB API token:\n'
                'flutter run --dart-define=TMDB_API_TOKEN=your_token\n\n'
                'You can still add this movie manually.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

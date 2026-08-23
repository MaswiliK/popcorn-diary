import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/config.dart';
import '../core/providers.dart';
import '../core/theme/app_colors.dart';

/// The "More" tab: settings, collection stats, cache management, and
/// (later, Phase 6) the "Back up your cinema" sign-in prompt — kept out
/// of the main flow per the no-login-wall onboarding principle.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text('More', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          _SectionLabel('Your Collection'),
          _CollectionSummaryTile(),
          const SizedBox(height: 24),
          _SectionLabel('Data'),
          const _MoreTile(
            icon: Icons.cloud_outlined,
            title: 'Back up your cinema',
            subtitle: 'Sign in to preserve your collection',
          ),
          _CacheManagementTile(),
          const SizedBox(height: 24),
          _SectionLabel('About'),
          const _AppInfoTile(),
          const _TmdbAttributionTile(),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _CollectionSummaryTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(movieEntryCountProvider);
    return _MoreTile(
      icon: Icons.local_movies_outlined,
      title: 'Movies in your diary',
      subtitle: countAsync.when(
        data: (count) => count == 1 ? '1 movie' : '$count movies',
        loading: () => 'Loading…',
        error: (_, __) => 'Unavailable',
      ),
    );
  }
}

/// Shows how many movies have cached TMDB metadata and lets the user
/// clear that cache. Clearing does NOT touch the diary itself — only
/// forces the next view of each movie to refetch from TMDB.
class _CacheManagementTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheCountAsync = ref.watch(metadataCacheCountProvider);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.cached_outlined, color: AppColors.accent),
      title: const Text('Clear cached movie data'),
      subtitle: Text(
        cacheCountAsync.when(
          data: (count) => count == 0
              ? 'Nothing cached yet'
              : '$count movie${count == 1 ? '' : 's'} cached from TMDB',
          loading: () => 'Loading…',
          error: (_, __) => 'Unavailable',
        ),
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: cacheCountAsync.maybeWhen(
        data: (count) => count > 0
            ? const Icon(Icons.chevron_right, color: AppColors.textTertiary)
            : null,
        orElse: () => null,
      ),
      onTap: () => _confirmClear(context, ref),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final count = await ref.read(metadataCacheCountProvider.future);
    if (count == 0) return;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Clear cached movie data?'),
        content: const Text(
          'This clears locally cached TMDB details (posters, cast, genres, '
          'etc). Your diary entries, ratings, and notes are not affected — '
          'movie details will just refetch next time you view them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Clear', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(metadataCacheRepositoryProvider).clear();
      ref.invalidate(metadataCacheCountProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cached movie data cleared.')),
        );
      }
    }
  }
}

class _AppInfoTile extends StatelessWidget {
  const _AppInfoTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final versionText = info == null
            ? 'Popcorn Diary'
            : '${info.appName} v${info.version} (${info.buildNumber})';
        return _MoreTile(
          icon: Icons.info_outline,
          title: 'About Popcorn Diary',
          subtitle: versionText,
        );
      },
    );
  }
}

/// TMDB's API terms require visible attribution wherever their data is
/// used — this satisfies that, and doubles as a quick way for the user
/// to confirm whether search/autofill is configured.
class _TmdbAttributionTile extends StatelessWidget {
  const _TmdbAttributionTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This product uses the TMDB API but is not endorsed or '
            'certified by TMDB.',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                AppConfig.hasTmdbToken
                    ? Icons.check_circle
                    : Icons.error_outline,
                size: 14,
                color: AppConfig.hasTmdbToken
                    ? AppColors.success
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                AppConfig.hasTmdbToken
                    ? 'TMDB search is configured'
                    : 'TMDB search is not configured',
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: AppColors.textSecondary))
          : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';

/// "Your Cinema" — analytics about the user's taste, not productivity
/// analytics. Phase 0/1 shows basic collection counts; Phase 5 expands
/// this into rating distributions, genre/director stats, and the WTF Index.
class YourCinemaScreen extends ConsumerWidget {
  const YourCinemaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(movieEntriesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Your Cinema', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            const Text('My statistics. My taste. My timeline.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Expanded(
              child: entriesAsync.when(
                data: (entries) {
                  final total = entries.length;
                  final rated = entries.where((e) => e.rating != null).toList();
                  final avg = rated.isEmpty
                      ? null
                      : rated.map((e) => e.rating!).reduce((a, b) => a + b) / rated.length;
                  return GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(label: 'Total movies', value: '$total'),
                      _StatCard(
                          label: 'Average rating',
                          value: avg == null ? '–' : avg.toStringAsFixed(1)),
                      _StatCard(
                          label: '9+/10 movies',
                          value: '${rated.where((e) => e.rating! >= 9).length}'),
                      _StatCard(
                          label: '10/10 movies',
                          value: '${rated.where((e) => e.rating! == 10).length}'),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('$err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.accent)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Placeholder for Phase 4 (Discover V0.1): daily cinema facts, actor/
/// director/genre facts, cached for offline display.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('Discover', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text(
              'Cinema facts and recommendations\ncoming in a later phase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

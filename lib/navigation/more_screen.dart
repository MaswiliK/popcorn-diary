import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Overflow tab: settings and, later, the "Back up your cinema" sign-in
/// prompt (Phase 6) — kept out of the main flow per the no-login-wall
/// onboarding principle.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text('More', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          const _MoreTile(icon: Icons.cloud_outlined, title: 'Back up your cinema', subtitle: 'Sign in to preserve your collection'),
          const _MoreTile(icon: Icons.settings_outlined, title: 'Settings'),
          const _MoreTile(icon: Icons.info_outline, title: 'About Popcorn Diary'),
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
          ? Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary))
          : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}

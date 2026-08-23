import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';

void main() {
  runApp(const ProviderScope(child: PopcornDiaryApp()));
}

class PopcornDiaryApp extends StatelessWidget {
  const PopcornDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Popcorn Diary',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}

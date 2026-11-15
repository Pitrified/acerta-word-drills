import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/about/about_screen.dart';
import 'screens/hidden_words/hidden_words_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/round/round_screen.dart';
import 'screens/settings/settings_screen.dart';

/// Route path constants.
abstract final class AppRoutes {
  static const home = '/';
  static const round = '/round';
  static const settings = '/settings';
  static const hiddenWords = '/settings/hidden';
  static const reports = '/settings/reports';
  static const progress = '/progress';
  static const about = '/about';
}

/// App-level GoRouter configuration.
///
/// Uses manual Provider (not @riverpod) because GoRouter setup is declarative
/// configuration, not async/stateful logic. This is a common Flutter pattern.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.round,
        builder: (context, state) => const RoundScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.hiddenWords,
        builder: (context, state) => const HiddenWordsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});

/// Root application widget.
class AcertaApp extends ConsumerWidget {
  const AcertaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'acerta',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

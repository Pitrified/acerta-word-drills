import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/home/home_screen.dart';
import 'screens/round/round_screen.dart';

/// Route path constants.
abstract final class AppRoutes {
  static const home = '/';
  static const round = '/round';
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

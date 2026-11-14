import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../providers/cards_provider.dart';
import '../../providers/round_provider.dart';
import '../../services/logging/app_logger.dart';

/// The landing screen: starts a round once the words are loaded.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('acerta')),
      body: Center(
        child: cards.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) {
            AppLogger.instance.error('Loading the words failed', cause: error);
            return const Text('The words could not be loaded.');
          },
          data: (_) => FilledButton(
            key: const Key('start-round'),
            onPressed: () {
              unawaited(ref.read(roundProvider.notifier).start());
              unawaited(context.push(AppRoutes.round));
            },
            child: const Text('Start round'),
          ),
        ),
      ),
    );
  }
}

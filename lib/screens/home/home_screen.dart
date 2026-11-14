import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../providers/cards_provider.dart';
import '../../providers/round_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/words_provider.dart';
import '../../services/logging/app_logger.dart';
import '../../utils/format_count.dart';

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
          data: (_) => const _Loaded(),
        ),
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final pool = ref.watch(poolSizesProvider).value?[settings.answerLanguage];
    final setup = [
      'Up to ${settings.maxLevel.label}',
      '${settings.pairsPerRound} pairs',
      settings.answerLanguage.label,
      if (pool != null) formatWords(pool),
    ].join(' · ');
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          setup,
          key: const Key('home-setup'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            key: const Key('start-round'),
            onPressed: () {
              unawaited(ref.read(roundProvider.notifier).start());
              unawaited(context.push(AppRoutes.round));
            },
            child: const Text('Start round'),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          key: const Key('home-progress'),
          leading: const Icon(Icons.bar_chart),
          title: const Text('Progress'),
          onTap: () => unawaited(context.push(AppRoutes.progress)),
        ),
        ListTile(
          key: const Key('home-settings'),
          leading: const Icon(Icons.tune),
          title: const Text('Settings'),
          onTap: () => unawaited(context.push(AppRoutes.settings)),
        ),
        ListTile(
          key: const Key('home-about'),
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          onTap: () => unawaited(context.push(AppRoutes.about)),
        ),
      ],
    );
  }
}

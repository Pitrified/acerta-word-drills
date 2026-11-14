import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/words_provider.dart';
import '../../utils/format_count.dart';
import '../../widgets/async_value_view.dart';

/// How much of each level has been seen, and the words missed most.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(levelProgressProvider);
    final missed = ref.watch(mostMissedProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: AsyncValueView(
        value: levels,
        builder: (levelList) {
          final seenTotal = levelList.fold(0, (sum, l) => sum + l.seen);
          final total = levelList.fold(0, (sum, l) => sum + l.total);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final level in levelList)
                Padding(
                  key: Key('progress-${level.level.label}'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${level.level.label}: ${formatCount(level.seen)} of '
                        '${formatCount(level.total)} words seen',
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: level.total == 0 ? 0 : level.seen / level.total,
                      ),
                    ],
                  ),
                ),
              Text(
                'Total: ${formatCount(seenTotal)} of '
                '${formatCount(total)} words seen',
                key: const Key('progress-total'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text('Most missed', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ...missed.when(
                loading: () => const <Widget>[],
                error: (error, stack) => const <Widget>[],
                data: (words) => words.isEmpty
                    ? const [Text('No missed words yet.')]
                    : [
                        for (final word in words)
                          ListTile(
                            key: Key('missed-${word.card.id}'),
                            contentPadding: EdgeInsets.zero,
                            title: Text(word.card.text),
                            subtitle: Text(
                              word.card.en.isEmpty ? '' : word.card.en.first,
                            ),
                            trailing: Text(
                              'missed ${word.progress.errors} of '
                              '${word.progress.seen}',
                            ),
                          ),
                      ],
              ),
            ],
          );
        },
      ),
    );
  }
}

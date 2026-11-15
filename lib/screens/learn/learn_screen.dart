import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../providers/learn_provider.dart';
import '../../widgets/async_value_view.dart';

/// The words marked to learn, newest first, with Remove on each.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Words to learn')),
      body: AsyncValueView(
        value: ref.watch(learnWordsProvider),
        builder: (words) {
          if (words.isEmpty) {
            return const Center(child: Text('No words to learn.'));
          }
          return ListView(
            children: [
              for (final (:card, markedAt: _) in words)
                ListTile(
                  key: Key('learn-row-${card.id}'),
                  onTap: () => unawaited(context.push(AppRoutes.word(card.id))),
                  title: Text(card.text),
                  subtitle: Text(
                    [
                      if (card.en.isNotEmpty) card.en.first,
                      if (card.it.isNotEmpty) card.it.first,
                      card.level.label,
                    ].join(' · '),
                  ),
                  trailing: TextButton(
                    key: Key('learn-remove-${card.id}'),
                    onPressed: () => unawaited(
                      ref.read(learnProvider.notifier).remove(card.id),
                    ),
                    child: const Text('Remove'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

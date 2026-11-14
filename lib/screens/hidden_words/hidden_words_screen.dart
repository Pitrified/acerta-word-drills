import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/progress_provider.dart';
import '../../providers/words_provider.dart';
import '../../widgets/async_value_view.dart';

/// The words hidden from the drill, each with a button to bring it back.
class HiddenWordsScreen extends ConsumerWidget {
  const HiddenWordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hidden words')),
      body: AsyncValueView(
        value: ref.watch(hiddenWordsProvider),
        builder: (words) {
          if (words.isEmpty) {
            return const Center(child: Text('No hidden words.'));
          }
          return ListView(
            children: [
              for (final card in words)
                ListTile(
                  key: Key('hidden-${card.id}'),
                  title: Text(card.text),
                  subtitle: Text(card.en.isEmpty ? '' : card.en.first),
                  trailing: TextButton(
                    key: Key('restore-${card.id}'),
                    onPressed: () => unawaited(
                      ref
                          .read(progressProvider.notifier)
                          .setHidden(card.id, hidden: false),
                    ),
                    child: const Text('Restore'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/round_state.dart';
import '../../providers/round_provider.dart';
import 'widgets/word_tile.dart';

/// The pair matching round: Portuguese words on the left, answers on the right.
class RoundScreen extends ConsumerWidget {
  const RoundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roundProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pair matching')),
      body: switch (state.status) {
        RoundStatus.loading => const Center(child: CircularProgressIndicator()),
        RoundStatus.notEnoughWords => const _NotEnoughWords(),
        RoundStatus.playing => _Board(state: state),
        RoundStatus.finished => const _Finished(),
      },
    );
  }
}

class _NotEnoughWords extends StatelessWidget {
  const _NotEnoughWords();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Not enough words for a round at this level.'),
          SizedBox(height: 16),
          _HomeButton(),
        ],
      ),
    );
  }
}

class _Finished extends ConsumerWidget {
  const _Finished();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Round done', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('next-round'),
            onPressed: () => ref.read(roundProvider.notifier).start(),
            child: const Text('Next round'),
          ),
          const SizedBox(height: 12),
          const _HomeButton(),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: const Key('round-home'),
      onPressed: () => context.go(AppRoutes.home),
      child: const Text('Home'),
    );
  }
}

class _Board extends ConsumerWidget {
  const _Board({required this.state});

  final RoundState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final round = state.round!;
    final notifier = ref.read(roundProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        for (final pair in round.pairs)
                          WordTile(
                            key: Key('left-${pair.left}'),
                            text: pair.left,
                            status: _status(
                              word: pair.left,
                              selected: state.selectedLeft,
                              matched: state.matchedLeft,
                              wrong: state.wrongLeft,
                            ),
                            onTap: () => notifier.tapLeft(pair.left),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        for (final right in round.rightColumn)
                          WordTile(
                            key: Key('right-$right'),
                            text: right,
                            status: _status(
                              word: right,
                              selected: state.selectedRight,
                              matched: state.matchedRight,
                              wrong: state.wrongRight,
                            ),
                            onTap: () => notifier.tapRight(right),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Two lines of room, so the columns stay put for most notes; a
          // longer note takes the height it needs.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Text(
              state.feedback ?? '',
              key: const Key('round-feedback'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  WordTileStatus _status({
    required String word,
    required String? selected,
    required Set<String> matched,
    required String? wrong,
  }) {
    if (matched.contains(word)) return WordTileStatus.matched;
    if (wrong == word) return WordTileStatus.wrong;
    if (selected == word) return WordTileStatus.selected;
    return WordTileStatus.idle;
  }
}

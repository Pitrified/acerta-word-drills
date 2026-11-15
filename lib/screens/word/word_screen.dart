import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/meaning.dart';
import '../../models/word_card.dart';
import '../../providers/cards_provider.dart';
import '../../providers/meanings_provider.dart';
import '../../widgets/async_value_view.dart';

/// How many other meanings show before `Show all`.
const otherMeaningsShown = 5;

/// One word: the other words for its meaning, and its other meanings.
class WordScreen extends ConsumerWidget {
  const WordScreen({required this.cardId, super.key});

  /// The id of the card.
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardRepositoryProvider);
    final card = cards.value?.byId(cardId);
    return Scaffold(
      key: Key('word-$cardId'),
      appBar: AppBar(title: Text(card?.text ?? 'Word')),
      body: AsyncValueView(
        value: cards,
        builder: (repository) {
          if (card == null) return const _NoDetails();
          return AsyncValueView(
            value: ref.watch(wordMeaningsProvider(cardId)),
            errorText: 'The meanings could not be loaded.',
            builder: (meanings) => meanings.isEmpty
                ? const _NoDetails()
                : _WordBody(card: card, meanings: meanings),
          );
        },
      ),
    );
  }
}

class _NoDetails extends StatelessWidget {
  const _NoDetails();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('No details for this word.'));
}

class _WordBody extends ConsumerWidget {
  const _WordBody({required this.card, required this.meanings});

  final WordCard card;

  /// The meanings of the card, its own first; never empty.
  final List<WordMeaning> meanings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final own = meanings.first.meaning;
    final others = meanings.skip(1).toList();
    final showAll = ref.watch(showAllMeaningsProvider(card.id));
    final shown = showAll ? others : others.take(otherMeaningsShown).toList();
    // At most 44 meanings, so they are all built and none is lazy.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.text, style: theme.textTheme.headlineMedium),
          Text(
            '${card.level.label} · ${card.pos}',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          Column(
            key: const Key('word-this'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This meaning', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(card.gloss),
              if (own.glossPt != null)
                Text(own.glossPt!, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              _WordGroups(
                meaning: own,
                ownText: card.text,
                labels: const {
                  'pt': 'Also in Portuguese',
                  'en': 'In English',
                  'it': 'In Italian',
                },
                emptyText: 'No other words for this meaning.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            key: const Key('word-others'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Other meanings', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              if (others.isEmpty) const Text('No other meanings.'),
              for (final other in shown)
                _OtherMeaning(other: other, ownText: card.text),
              if (!showAll && others.length > otherMeaningsShown)
                TextButton(
                  key: const Key('word-show-all'),
                  onPressed: () => ref
                      .read(showAllMeaningsProvider(card.id).notifier)
                      .show(),
                  child: Text('Show all (${others.length})'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OtherMeaning extends StatelessWidget {
  const _OtherMeaning({required this.other, required this.ownText});

  final WordMeaning other;
  final String ownText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meaning = other.meaning;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(other.level.label, style: theme.textTheme.labelLarge),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(meaning.gloss, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            if (meaning.glossPt != null)
              Text(meaning.glossPt!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            _WordGroups(
              meaning: meaning,
              ownText: ownText,
              labels: const {
                'pt': 'Portuguese',
                'en': 'English',
                'it': 'Italian',
              },
              emptyText: 'No other words.',
            ),
          ],
        ),
      ),
    );
  }
}

/// The words of a meaning, a row per language that has any; the word
/// [ownText] is left out of the Portuguese row.
class _WordGroups extends StatelessWidget {
  const _WordGroups({
    required this.meaning,
    required this.ownText,
    required this.labels,
    required this.emptyText,
  });

  final Meaning meaning;
  final String ownText;

  /// The row label of each language code.
  final Map<String, String> labels;

  /// What is said when no language has a word left.
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];
    for (final MapEntry(key: language, value: label) in labels.entries) {
      final words = [
        for (final word in meaning.words[language] ?? const <MeaningWord>[])
          if (language != 'pt' || word.text != ownText) word,
      ];
      if (words.isEmpty) continue;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              Wrap(
                spacing: 6,
                children: [
                  for (final word in words)
                    Chip(
                      label: Text(word.label),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    if (rows.isEmpty) return Text(emptyText);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

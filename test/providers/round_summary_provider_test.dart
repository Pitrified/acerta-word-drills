import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/lookalike.dart';
import 'package:acerta/models/round_summary.dart';
import 'package:acerta/providers/progress_provider.dart';
import 'package:acerta/providers/round_provider.dart';
import 'package:acerta/providers/round_summary_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: roundOverrides(
        cards: fakeCardRepository(12),
        progress: FakeProgressRepository(),
      ),
    );
    addTearDown(container.dispose);
  });

  test('is null before a round', () {
    expect(container.read(roundSummaryProvider), isNull);
  });

  test('has one entry per pair, in round order', () async {
    await container.read(roundProvider.notifier).start();
    final round = container.read(roundProvider).round!;
    final summary = container.read(roundSummaryProvider)!;
    expect(summary.entries.map((e) => e.pair), round.pairs);
  });

  test('marks the missed cards and counts the right first time', () async {
    final notifier = container.read(roundProvider.notifier);
    await notifier.start();
    final pairs = container.read(roundProvider).round!.pairs;
    await notifier.tapLeft(pairs[0].left);
    await notifier.tapRight(pairs[1].right);
    for (final pair in pairs) {
      await notifier.tapLeft(pair.left);
      await notifier.tapRight(pair.right);
    }
    final summary = container.read(roundSummaryProvider)!;
    expect(
      {for (final e in summary.entries) e.pair.card.id: e.missed},
      {for (final pair in pairs) pair.card.id: pair == pairs[0]},
    );
    expect(summary.rightFirstTime, pairs.length - 1);
  });

  test('follows the hidden flag of the progress', () async {
    await container.read(roundProvider.notifier).start();
    final id = container.read(roundSummaryProvider)!.entries.first.pair.card.id;
    expect(container.read(roundSummaryProvider)!.entries.first.hidden, isFalse);
    await container.read(progressProvider.notifier).setHidden(id, hidden: true);
    expect(container.read(roundSummaryProvider)!.entries.first.hidden, isTrue);
  });

  group('false friends', () {
    const parz = Lookalike(
      language: 'it',
      text: 'parz0',
      kind: LookalikeKind.partial,
      note: 'shares a meaning',
    );
    const part = Lookalike(
      language: 'en',
      text: 'part1',
      kind: LookalikeKind.partial,
    );
    final full = fakeCard(0).lookalikes.single;
    final cards = cardRepositoryOf([
      fakeCard(0, lookalikes: [full, parz]),
      fakeCard(1, lookalikes: const [part]),
      // A look-alike that is a word of the card's own meaning is no trap.
      fakeCard(
        2,
        lookalikes: const [
          Lookalike(language: 'it', text: 'it2', kind: LookalikeKind.partial),
        ],
      ),
      fakeCard(3, lookalikes: const []),
    ]);

    ProviderContainer containerFor(AnswerLanguage language) {
      final container = ProviderContainer(
        overrides: roundOverrides(
          cards: cards,
          progress: FakeProgressRepository(),
          settings: FakeSettingsRepository(
            DrillSettings(pairsPerRound: 4, answerLanguage: language),
          ),
        ),
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<RoundSummary> summaryOf(AnswerLanguage language) async {
      final container = containerFor(language);
      await container.read(roundProvider.notifier).start();
      final summary = container.read(roundSummaryProvider);
      return summary!;
    }

    List<(String, Lookalike, bool)> rows(RoundSummary summary) => [
      for (final e in summary.falseFriends)
        (e.pair.card.id, e.lookalike, e.onBoard),
    ];

    test('lists both languages, the answer language and full first', () async {
      final summary = await summaryOf(AnswerLanguage.en);
      final byCard = {
        'id0': [('id0', full, true), ('id0', parz, false)],
        'id1': [('id1', part, false)],
      };
      expect(rows(summary), [
        for (final e in summary.entries) ...?byCard[e.pair.card.id],
      ]);
    });

    test('an Italian round lists the Italian ones first', () async {
      final summary = await summaryOf(AnswerLanguage.it);
      final byCard = {
        // No full false friend in Italian, so no decoy is on the board.
        'id0': [('id0', parz, false), ('id0', full, false)],
        'id1': [('id1', part, false)],
      };
      expect(rows(summary), [
        for (final e in summary.entries) ...?byCard[e.pair.card.id],
      ]);
    });

    test('a round with no false friend has none', () async {
      final container = ProviderContainer(
        overrides: roundOverrides(
          cards: cardRepositoryOf([
            for (var i = 0; i < 6; i++) fakeCard(i, lookalikes: const []),
          ]),
          progress: FakeProgressRepository(),
        ),
      );
      addTearDown(container.dispose);
      await container.read(roundProvider.notifier).start();
      expect(container.read(roundSummaryProvider)!.falseFriends, isEmpty);
    });
  });
}

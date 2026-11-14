import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/lookalike.dart';
import 'package:acerta/models/pair_round.dart';
import 'package:acerta/models/round_state.dart';
import 'package:acerta/providers/round_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

Future<void> _match(WidgetTester tester, RoundPair pair) async {
  await tapKey(tester, 'left-${pair.left}');
  await tapKey(tester, 'right-${pair.right}');
}

/// Starts a round from the home screen and plays it, missing [missFirst] first.
Future<List<RoundPair>> _playRound(
  WidgetTester tester,
  ProviderContainer container, {
  bool missFirst = true,
}) async {
  await tapKey(tester, 'start-round');
  final pairs = container.read(roundProvider).round!.pairs;
  if (missFirst) {
    await tapKey(tester, 'left-${pairs[0].left}');
    await tapKey(tester, 'right-${pairs[1].right}');
  }
  for (final pair in pairs) {
    await _match(tester, pair);
  }
  expect(container.read(roundProvider).status, RoundStatus.finished);
  return pairs;
}

void main() {
  testWidgets('shows one entry per pair, in round order', (tester) async {
    final container = await pumpApp(tester);
    final pairs = await _playRound(tester, container);

    expect(find.text('Round done'), findsOneWidget);
    for (final pair in pairs) {
      final entry = find.byKey(Key('summary-${pair.card.id}'));
      expect(entry, findsOneWidget);
      expect(
        find.descendant(
          of: entry,
          matching: find.text('${pair.left} - ${pair.right}'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: entry, matching: find.text(pair.card.gloss)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: entry, matching: find.text('A1 · noun')),
        findsOneWidget,
      );
    }
    final tops = [
      for (final pair in pairs)
        tester.getTopLeft(find.byKey(Key('summary-${pair.card.id}'))).dy,
    ];
    expect(tops, [...tops]..sort());
  });

  testWidgets('says how many pairs were right first time', (tester) async {
    final container = await pumpApp(tester);
    final pairs = await _playRound(tester, container);
    expect(
      tester.widget<Text>(find.byKey(const Key('summary-score'))).data,
      '${pairs.length - 1} of ${pairs.length} right first time',
    );
  });

  testWidgets('a round with no miss is all right first time', (tester) async {
    final container = await pumpApp(tester);
    final pairs = await _playRound(tester, container, missFirst: false);
    expect(
      tester.widget<Text>(find.byKey(const Key('summary-score'))).data,
      '${pairs.length} of ${pairs.length} right first time',
    );
    expect(find.text('missed'), findsNothing);
  });

  testWidgets('marks the missed card and no other', (tester) async {
    final container = await pumpApp(tester);
    final pairs = await _playRound(tester, container);

    expect(find.text('missed'), findsOneWidget);
    expect(find.byKey(Key('missed-${pairs[0].card.id}')), findsOneWidget);
    for (final pair in pairs.skip(1)) {
      expect(find.byKey(Key('missed-${pair.card.id}')), findsNothing);
    }
  });

  testWidgets('lists every look-alike with its language, kind and note', (
    tester,
  ) async {
    final bare = fakeCard(0, lookalikes: const []);
    final mixed = fakeCard(
      1,
      lookalikes: const [
        Lookalike(language: 'it', text: 'cogn', kind: LookalikeKind.cognate),
        Lookalike(
          language: 'en',
          text: 'part',
          kind: LookalikeKind.partial,
          note: 'half the meaning',
        ),
      ],
    );
    final full = fakeCard(2, level: Level.a1);
    final container = await pumpApp(
      tester,
      cards: cardRepositoryOf([bare, mixed, full]),
      settings: FakeSettingsRepository(const DrillSettings(pairsPerRound: 3)),
    );
    await _playRound(tester, container, missFirst: false);

    expect(find.byKey(const Key('summary-id0')), findsOneWidget);
    expect(find.textContaining('English:'), findsNWidgets(2));
    expect(find.text('Italian: cogn (cognate)'), findsOneWidget);
    expect(
      find.text('English: part (partial false friend) - half the meaning'),
      findsOneWidget,
    );
    expect(find.text('English: look2 (false friend) - note 2'), findsOneWidget);
  });

  testWidgets('the gloss stays English with Italian answers', (tester) async {
    final container = await pumpApp(
      tester,
      settings: FakeSettingsRepository(
        const DrillSettings(answerLanguage: AnswerLanguage.it),
      ),
    );
    final pairs = await _playRound(tester, container, missFirst: false);
    expect(pairs.first.right, startsWith('it'));
    expect(find.text(pairs.first.card.gloss), findsOneWidget);
  });

  testWidgets(
    'Don\'t show again hides the word, and Hidden, undo restores it',
    (tester) async {
      final progress = FakeProgressRepository();
      final container = await pumpApp(tester, progress: progress);
      final pairs = await _playRound(tester, container);
      final id = pairs[2].card.id;

      expect(find.text("Don't show again"), findsNWidgets(pairs.length));
      await tapKey(tester, 'hide-$id');
      expect(progress.of(id)!.hidden, isTrue);
      expect(find.text('Hidden, undo'), findsOneWidget);
      expect(find.text("Don't show again"), findsNWidgets(pairs.length - 1));

      await tapKey(tester, 'hide-$id');
      expect(progress.of(id)!.hidden, isFalse);
      expect(find.text('Hidden, undo'), findsNothing);
    },
  );

  testWidgets('a hidden word is not drawn in later rounds', (tester) async {
    var now = fixedNow;
    final container = await pumpApp(tester, clock: () => now);
    final pairs = await _playRound(tester, container);
    final hiddenIds = {pairs[0].card.id, pairs[1].card.id};
    for (final id in hiddenIds) {
      await tapKey(tester, 'hide-$id');
    }

    // A day passes between rounds, so the recency of a played word is no
    // reason for it to be left out: only the hidden flag is.
    for (var i = 0; i < 8; i++) {
      now = now.add(const Duration(days: 1));
      await tapKey(tester, 'next-round');
      final round = container.read(roundProvider).round!;
      final drawn = round.pairs.map((p) => p.card.id).toSet();
      expect(drawn.intersection(hiddenIds), isEmpty);
      for (final pair in round.pairs) {
        await _match(tester, pair);
      }
    }
  });

  testWidgets('Next round starts another round', (tester) async {
    final container = await pumpApp(tester);
    final pairs = await _playRound(tester, container);
    await tapKey(tester, 'next-round');

    final state = container.read(roundProvider);
    expect(state.status, RoundStatus.playing);
    expect(state.round!.pairs, isNot(pairs));
    expect(find.byKey(Key('summary-${pairs[0].card.id}')), findsNothing);
  });

  testWidgets('Home leaves the summary', (tester) async {
    final container = await pumpApp(tester);
    await _playRound(tester, container);
    await tapKey(tester, 'round-home');
    expect(find.byKey(const Key('start-round')), findsOneWidget);
  });

  testWidgets('8 pairs with long notes fit a small phone', (tester) async {
    useSmallPhone(tester);
    final note = List.filled(10, 'a note').join(', ').padRight(100, 'x');
    final cards = [
      for (var i = 0; i < 20; i++)
        fakeCard(
          i,
          lookalikes: [
            Lookalike(
              language: 'en',
              text: 'lookalike$i',
              kind: LookalikeKind.full,
              note: note.substring(0, 100),
            ),
            Lookalike(
              language: 'it',
              text: 'somiglianza$i',
              kind: LookalikeKind.partial,
              note: note.substring(0, 100),
            ),
          ],
        ),
    ];
    final container = await pumpApp(
      tester,
      cards: cardRepositoryOf(cards),
      settings: FakeSettingsRepository(const DrillSettings(pairsPerRound: 8)),
    );
    final pairs = await _playRound(tester, container);

    expect(pairs, hasLength(8));
    expect(tester.takeException(), isNull);
    // The buttons are in reach without scrolling, and so is the last entry
    // after scrolling.
    expect(
      tester.getBottomLeft(find.byKey(const Key('next-round'))).dy,
      lessThan(568),
    );
    await tester.ensureVisible(find.byKey(Key('hide-${pairs.last.card.id}')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('round-home')), findsOneWidget);
  });
}

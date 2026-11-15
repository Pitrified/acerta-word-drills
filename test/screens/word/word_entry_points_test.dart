import 'package:acerta/models/pair_round.dart';
import 'package:acerta/providers/round_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  final meanings = meaningsRepositoryOf(
    meanings: [
      for (var i = 0; i < 12; i++)
        {
          'gloss': 'gloss $i',
          'pt': [
            ['w$i', 'A1'],
            ['syn$i', 'B2'],
          ],
        },
    ],
    cards: {
      for (var i = 0; i < 12; i++)
        'id$i': [
          [i, 'A1'],
        ],
    },
  );

  testWidgets('the round summary opens the word page and back returns', (
    tester,
  ) async {
    final container = await pumpApp(tester, meanings: meanings);
    await tapKey(tester, 'start-round');
    final pairs = container.read(roundProvider).round!.pairs;
    for (final RoundPair(:left, :right) in pairs) {
      await tapKey(tester, 'left-$left');
      await tapKey(tester, 'right-$right');
    }
    final id = pairs[0].card.id;

    await tapKey(tester, 'summary-open-$id');

    expect(find.byKey(Key('word-$id')), findsOneWidget);
    expect(find.text('syn${id.substring(2)} · B2'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('next-round')), findsOneWidget);
    expect(find.byKey(Key('word-$id')), findsNothing);
  });

  testWidgets('a button of the summary card does not open the page', (
    tester,
  ) async {
    final container = await pumpApp(tester, meanings: meanings);
    await tapKey(tester, 'start-round');
    final pairs = container.read(roundProvider).round!.pairs;
    for (final RoundPair(:left, :right) in pairs) {
      await tapKey(tester, 'left-$left');
      await tapKey(tester, 'right-$right');
    }
    final id = pairs[0].card.id;

    await tapKey(tester, 'learn-$id');

    expect(find.byKey(Key('word-$id')), findsNothing);
    expect(find.text('To learn, undo'), findsOneWidget);
  });

  testWidgets('a words to learn row opens the word page', (tester) async {
    final learn = FakeLearnRepository({'id1': fixedNow, 'id2': fixedNow});
    await pumpApp(tester, meanings: meanings, learn: learn);
    await tapKey(tester, 'home-settings');
    await tapKey(tester, 'settings-learn');

    await tapKey(tester, 'learn-row-id1');

    expect(find.byKey(const Key('word-id1')), findsOneWidget);
    expect(find.text('syn1 · B2'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('learn-row-id2')), findsOneWidget);
  });

  testWidgets('Remove still removes the word and opens no page', (
    tester,
  ) async {
    final learn = FakeLearnRepository({'id1': fixedNow});
    await pumpApp(tester, meanings: meanings, learn: learn);
    await tapKey(tester, 'home-settings');
    await tapKey(tester, 'settings-learn');

    await tapKey(tester, 'learn-remove-id1');

    expect(find.byKey(const Key('word-id1')), findsNothing);
    expect(find.text('No words to learn.'), findsOneWidget);
    expect(learn.all, isEmpty);
  });
}

import 'package:acerta/models/level.dart';
import 'package:acerta/models/word_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

Future<void> _open(
  WidgetTester tester, {
  required FakeLearnRepository learn,
  List<WordCard>? cards,
}) async {
  await pumpApp(
    tester,
    learn: learn,
    cards: cards == null ? null : cardRepositoryOf(cards),
  );
  await tapKey(tester, 'home-settings');
  await tapKey(tester, 'settings-learn');
}

void main() {
  testWidgets('lists the words newest mark first with their details', (
    tester,
  ) async {
    await _open(
      tester,
      learn: FakeLearnRepository({
        'id1': DateTime.utc(2026, 1, 1),
        'id3': DateTime.utc(2026, 1, 3),
        'id2': DateTime.utc(2026, 1, 2),
      }),
    );
    expect(find.text('w1'), findsOneWidget);
    expect(find.text('en1 · it1 · A1'), findsOneWidget);
    expect(find.text('No words to learn.'), findsNothing);
    final tops = [
      for (final id in ['id3', 'id2', 'id1'])
        tester.getTopLeft(find.byKey(Key('learn-row-$id'))).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(tops.toSet(), hasLength(3));
  });

  testWidgets('leaves out a missing translation', (tester) async {
    await _open(
      tester,
      learn: FakeLearnRepository({
        'id0': fixedNow,
        'id1': fixedNow,
        'id2': fixedNow,
      }),
      cards: [
        fakeCard(0, it: [], level: Level.b2),
        fakeCard(1, en: []),
        fakeCard(2, en: [], it: []),
      ],
    );
    expect(find.text('en0 · B2'), findsOneWidget);
    expect(find.text('it1 · A1'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
  });

  testWidgets('Remove drops the word from the list and the store', (
    tester,
  ) async {
    final learn = FakeLearnRepository({'id1': fixedNow, 'id2': fixedNow});
    await _open(tester, learn: learn);
    await tapKey(tester, 'learn-remove-id1');
    expect(learn.all.keys, ['id2']);
    expect(find.byKey(const Key('learn-row-id1')), findsNothing);
    expect(find.byKey(const Key('learn-row-id2')), findsOneWidget);
    await tapKey(tester, 'learn-remove-id2');
    expect(find.text('No words to learn.'), findsOneWidget);
  });

  testWidgets('says so when nothing is marked', (tester) async {
    await _open(tester, learn: FakeLearnRepository());
    expect(find.text('No words to learn.'), findsOneWidget);
  });

  testWidgets('skips an id that is not in the card set', (tester) async {
    await _open(
      tester,
      learn: FakeLearnRepository({'id1': fixedNow, 'gone': fixedNow}),
    );
    expect(find.byKey(const Key('learn-row-id1')), findsOneWidget);
    expect(find.byKey(const Key('learn-row-gone')), findsNothing);
  });
}

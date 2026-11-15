import 'package:acerta/app.dart';
import 'package:acerta/services/meanings/meanings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

/// A meaning of `w1` with a word at a level and one with none, and a card
/// that has [others] more meanings.
MeaningsRepository _repository({
  List<Map<String, Object?>>? own,
  int others = 1,
}) {
  final meanings = <Map<String, Object?>>[
    own?.first ??
        {
          'gloss': 'gloss 1',
          'gloss_pt': 'glosa 1',
          'pt': [
            ['w1', 'A1'],
            ['syn1', 'B2'],
          ],
          'en': [
            ['e1', 'B1'],
            ['e2', null],
          ],
          'it': [
            ['i1', 'C1'],
          ],
        },
    for (var i = 0; i < others; i++)
      {
        'gloss': 'other $i',
        'pt': [
          ['w1', 'B2'],
          ['otherpt$i', 'C1'],
        ],
        'en': [
          ['otheren$i', 'C2'],
        ],
      },
  ];
  return meaningsRepositoryOf(
    meanings: meanings,
    cards: {
      'id1': [
        for (var i = 0; i < meanings.length; i++) [i, i == 0 ? 'A1' : 'B2'],
      ],
    },
  );
}

Future<void> _open(
  WidgetTester tester,
  MeaningsRepository meanings, {
  String id = 'id1',
}) async {
  final container = await pumpApp(tester, meanings: meanings);
  container.read(routerProvider).push(AppRoutes.word(id)).ignore();
  await tester.pumpAndSettle();
}

Finder _in(String key, Finder matching) =>
    find.descendant(of: find.byKey(Key(key)), matching: matching);

void main() {
  testWidgets('shows the header, this meaning and the other meanings', (
    tester,
  ) async {
    await _open(tester, _repository());

    expect(find.byKey(const Key('word-id1')), findsOneWidget);
    expect(find.text('w1'), findsNWidgets(2));
    expect(find.text('A1 · noun'), findsOneWidget);

    expect(_in('word-this', find.text('This meaning')), findsOneWidget);
    expect(_in('word-this', find.text('gloss 1')), findsOneWidget);
    expect(_in('word-this', find.text('glosa 1')), findsOneWidget);
    expect(_in('word-this', find.text('Also in Portuguese')), findsOneWidget);
    expect(_in('word-this', find.text('syn1 · B2')), findsOneWidget);
    expect(_in('word-this', find.text('In English')), findsOneWidget);
    expect(_in('word-this', find.text('e1 · B1')), findsOneWidget);
    expect(_in('word-this', find.text('e2')), findsOneWidget);
    expect(_in('word-this', find.text('In Italian')), findsOneWidget);
    expect(_in('word-this', find.text('i1 · C1')), findsOneWidget);

    expect(_in('word-others', find.text('Other meanings')), findsOneWidget);
    expect(_in('word-others', find.text('other 0')), findsOneWidget);
    expect(_in('word-others', find.text('B2')), findsOneWidget);
    expect(_in('word-others', find.text('otherpt0 · C1')), findsOneWidget);
    expect(_in('word-others', find.text('otheren0 · C2')), findsOneWidget);
    expect(_in('word-others', find.text('No other meanings.')), findsNothing);
  });

  testWidgets('leaves the word itself out of the Portuguese words', (
    tester,
  ) async {
    await _open(tester, _repository());

    expect(find.text('w1 · A1'), findsNothing);
    expect(find.text('w1 · B2'), findsNothing);
  });

  testWidgets('does not show a language with no word', (tester) async {
    await _open(
      tester,
      _repository(
        own: [
          {
            'gloss': 'gloss 1',
            'pt': [
              ['w1', 'A1'],
              ['syn1', 'B2'],
            ],
            'en': [
              ['e1', 'B1'],
            ],
          },
        ],
      ),
    );

    expect(find.text('In English'), findsOneWidget);
    expect(find.text('In Italian'), findsNothing);
    expect(find.text('Italian'), findsNothing);
    expect(find.text('glosa 1'), findsNothing);
  });

  testWidgets('says so when the meaning has no other word', (tester) async {
    await _open(
      tester,
      _repository(
        own: [
          {
            'gloss': 'gloss 1',
            'pt': [
              ['w1', 'A1'],
            ],
          },
        ],
        others: 0,
      ),
    );

    expect(find.text('No other words for this meaning.'), findsOneWidget);
    expect(find.text('Also in Portuguese'), findsNothing);
    expect(find.text('No other meanings.'), findsOneWidget);
    expect(find.byKey(const Key('word-show-all')), findsNothing);
  });

  testWidgets('folds the other meanings after five until Show all', (
    tester,
  ) async {
    await _open(tester, _repository(others: 7));

    expect(find.text('other 4'), findsOneWidget);
    expect(find.text('other 5'), findsNothing);
    expect(find.text('Show all (7)'), findsOneWidget);

    await tapKey(tester, 'word-show-all');

    expect(find.text('other 6', skipOffstage: false), findsOneWidget);
    expect(find.byKey(const Key('word-show-all')), findsNothing);
  });

  testWidgets('does not fold five other meanings', (tester) async {
    await _open(tester, _repository(others: 5));

    expect(find.text('other 4'), findsOneWidget);
    expect(find.byKey(const Key('word-show-all')), findsNothing);
  });

  testWidgets('an unknown id has no details', (tester) async {
    await _open(tester, _repository(), id: 'nope');

    expect(find.text('No details for this word.'), findsOneWidget);
    expect(find.text('This meaning'), findsNothing);
  });

  testWidgets('a card with no meanings has no details', (tester) async {
    await _open(tester, _repository(), id: 'id2');

    expect(find.text('No details for this word.'), findsOneWidget);
    expect(find.text('w2'), findsOneWidget);
  });

  testWidgets('shows a spinner while the meanings load', (tester) async {
    final container = await pumpApp(
      tester,
      loadMeanings: () =>
          Future.delayed(const Duration(seconds: 1), () => _repository()),
    );
    container.read(routerProvider).push(AppRoutes.word('id1')).ignore();
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('This meaning'), findsOneWidget);
  });

  testWidgets('says so when the meanings cannot be read', (tester) async {
    final container = await pumpApp(
      tester,
      loadMeanings: () => Future.error(UnsupportedMeaningsFormatError(9)),
    );
    container.read(routerProvider).push(AppRoutes.word('id1')).ignore();
    await tester.pumpAndSettle();

    expect(find.text('The meanings could not be loaded.'), findsOneWidget);
  });
}

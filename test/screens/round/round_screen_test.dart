import 'package:acerta/app.dart';
import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/pair_round.dart';
import 'package:acerta/models/round_state.dart';
import 'package:acerta/providers/round_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  int cards = 12,
  DrillSettings settings = const DrillSettings(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: roundOverrides(
        cards: fakeCardRepository(cards),
        progress: FakeProgressRepository(),
        settings: FakeSettingsRepository(settings),
      ),
      child: const AcertaApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(AcertaApp)));
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _match(WidgetTester tester, RoundPair pair) async {
  await _tap(tester, 'left-${pair.left}');
  await _tap(tester, 'right-${pair.right}');
}

void main() {
  testWidgets('plays a round from the home screen and starts another', (
    tester,
  ) async {
    final container = await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('start-round')));
    await tester.pumpAndSettle();

    expect(find.text('Pair matching'), findsOneWidget);
    final round = container.read(roundProvider).round!;
    for (final pair in round.pairs) {
      expect(find.byKey(Key('left-${pair.left}')), findsOneWidget);
      expect(find.byKey(Key('right-${pair.right}')), findsOneWidget);
    }

    // One wrong tap on the way: the first left word with the second answer.
    await _tap(tester, 'left-${round.pairs[0].left}');
    await _tap(tester, 'right-${round.pairs[1].right}');
    expect(
      tester.widget<Text>(find.byKey(const Key('round-feedback'))).data,
      'Wrong pair.',
    );

    for (final pair in round.pairs) {
      await _match(tester, pair);
    }
    expect(container.read(roundProvider).status, RoundStatus.finished);
    expect(find.text('Round done'), findsOneWidget);

    await tester.tap(find.byKey(const Key('next-round')));
    await tester.pumpAndSettle();
    final next = container.read(roundProvider).round!;
    expect(container.read(roundProvider).status, RoundStatus.playing);
    expect(next, isNot(round));
    expect(find.byKey(Key('left-${next.pairs.first.left}')), findsOneWidget);

    await _match(tester, next.pairs.first);
    expect(container.read(roundProvider).matchedLeft, hasLength(1));
  });

  testWidgets('the Home button leaves a finished round', (tester) async {
    final container = await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('start-round')));
    await tester.pumpAndSettle();
    for (final pair in container.read(roundProvider).round!.pairs) {
      await _match(tester, pair);
    }
    await tester.tap(find.byKey(const Key('round-home')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start-round')), findsOneWidget);
    expect(find.text('Pair matching'), findsNothing);
  });

  testWidgets('a decoy tapped for its word shows the note', (tester) async {
    final container = await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('start-round')));
    await tester.pumpAndSettle();
    final decoy = container.read(roundProvider).round!.decoys.single;

    await _tap(tester, 'left-${decoy.left}');
    await _tap(tester, 'right-${decoy.text}');
    expect(
      tester.widget<Text>(find.byKey(const Key('round-feedback'))).data,
      'False friend! ${decoy.note}',
    );
  });

  testWidgets('says so when there are too few words', (tester) async {
    await _pumpApp(tester, cards: 1);
    await tester.tap(find.byKey(const Key('start-round')));
    await tester.pumpAndSettle();

    expect(
      find.text('Not enough words for a round at this level.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('round-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-round')), findsOneWidget);
  });

  testWidgets('the board sits at the bottom, feedback above equal tiles', (
    tester,
  ) async {
    // A tall phone with a system navigation bar of 48 at the bottom.
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);

    final container = await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('start-round')));
    await tester.pumpAndSettle();

    final round = container.read(roundProvider).round!;
    Rect rect(String key) => tester.getRect(find.byKey(Key(key)));
    final tiles = [
      for (final pair in round.pairs) rect('left-${pair.left}'),
      for (final right in round.rightColumn) rect('right-$right'),
    ];

    // Every tile is as wide as its column, and the columns are equal.
    expect({for (final tile in tiles) tile.width}, hasLength(1));
    expect(tiles.first.width, greaterThan(150));

    // The feedback is above the first tile.
    final firstTop = tiles
        .map((tile) => tile.top)
        .reduce((a, b) => a < b ? a : b);
    expect(rect('round-feedback').bottom, lessThanOrEqualTo(firstTop));

    // The last tile ends just above the navigation bar, not under it.
    final lastBottom = tiles
        .map((tile) => tile.bottom)
        .reduce((a, b) => a > b ? a : b);
    expect(lastBottom, lessThanOrEqualTo(915 - 48));
    expect(lastBottom, greaterThan(915 - 48 - 24));
  });

  testWidgets('8 pairs and a decoy fit a small phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = await _pumpApp(
      tester,
      cards: 20,
      settings: const DrillSettings(pairsPerRound: 8),
    );
    await tester.tap(find.byKey(const Key('start-round')));
    await tester.pumpAndSettle();

    final round = container.read(roundProvider).round!;
    expect(round.pairs, hasLength(8));
    expect(round.decoys, hasLength(1));
    expect(tester.takeException(), isNull);

    // The last tile is reachable by scrolling, and the round can be played.
    for (final pair in round.pairs) {
      await _match(tester, pair);
    }
    expect(tester.takeException(), isNull);
    expect(container.read(roundProvider).status, RoundStatus.finished);
  });
}

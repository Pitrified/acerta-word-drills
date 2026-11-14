import 'package:acerta/models/level.dart';
import 'package:acerta/models/word_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

Future<void> _open(
  WidgetTester tester, {
  required FakeProgressRepository progress,
  List<int> levels = const [0, 0, 0, 1, 2, 5],
}) async {
  await pumpApp(
    tester,
    progress: progress,
    cards: cardRepositoryOf([
      for (var i = 0; i < levels.length; i++)
        fakeCard(i, level: Level.values[levels[i]]),
    ]),
  );
  await tapKey(tester, 'home-progress');
}

void main() {
  testWidgets('shows the words seen out of the words at each level', (
    tester,
  ) async {
    await _open(
      tester,
      progress: FakeProgressRepository({
        'id0': const WordProgress(seen: 3),
        'id1': const WordProgress(seen: 1),
        'id3': const WordProgress(seen: 1),
        'id2': const WordProgress(hidden: true),
      }),
    );

    Finder line(String text, String level) => find.descendant(
      of: find.byKey(Key('progress-$level')),
      matching: find.text(text),
    );
    expect(line('A1: 2 of 3 words seen', 'A1'), findsOneWidget);
    expect(line('A2: 1 of 1 words seen', 'A2'), findsOneWidget);
    expect(line('B1: 0 of 1 words seen', 'B1'), findsOneWidget);
    expect(line('B2: 0 of 0 words seen', 'B2'), findsOneWidget);
    expect(line('C2: 0 of 1 words seen', 'C2'), findsOneWidget);
    for (final level in Level.values) {
      expect(
        find.descendant(
          of: find.byKey(Key('progress-${level.label}')),
          matching: find.byType(LinearProgressIndicator),
        ),
        findsOneWidget,
      );
    }
    final bar = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byKey(const Key('progress-A1')),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(bar.value, closeTo(2 / 3, 1e-9));
    expect(find.text('Total: 3 of 6 words seen'), findsOneWidget);
  });

  testWidgets('lists the most missed words, most errors first', (tester) async {
    await _open(
      tester,
      progress: FakeProgressRepository({
        'id1': const WordProgress(seen: 4, errors: 2),
        'id2': const WordProgress(seen: 3, errors: 2),
        'id3': const WordProgress(seen: 9, errors: 5),
        'id0': const WordProgress(seen: 2),
      }),
    );

    expect(find.text('No missed words yet.'), findsNothing);
    expect(find.text('missed 5 of 9'), findsOneWidget);
    expect(find.text('missed 2 of 4'), findsOneWidget);
    expect(find.text('en3'), findsOneWidget);
    expect(find.byKey(const Key('missed-id0')), findsNothing);
    double top(String id) =>
        tester.getTopLeft(find.byKey(Key('missed-$id'))).dy;
    expect(top('id3'), lessThan(top('id1')));
    expect(top('id1'), lessThan(top('id2')));
  });

  testWidgets('says so when no word was missed', (tester) async {
    await _open(
      tester,
      progress: FakeProgressRepository({'id0': const WordProgress(seen: 2)}),
    );
    expect(find.text('No missed words yet.'), findsOneWidget);
  });

  testWidgets('writes a count over 999 with a thousands separator', (
    tester,
  ) async {
    await _open(
      tester,
      progress: FakeProgressRepository({}),
      levels: List.filled(1200, 0),
    );
    expect(find.text('A1: 0 of 1,200 words seen'), findsOneWidget);
    expect(find.text('Total: 0 of 1,200 words seen'), findsOneWidget);
  });

  testWidgets('skips a progress id that is not in the card set', (
    tester,
  ) async {
    await _open(
      tester,
      progress: FakeProgressRepository({
        'gone': const WordProgress(seen: 5, errors: 5),
      }),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Total: 0 of 6 words seen'), findsOneWidget);
    expect(find.text('No missed words yet.'), findsOneWidget);
  });

  testWidgets('fits a 320 x 568 phone with a full most missed list', (
    tester,
  ) async {
    useSmallPhone(tester);
    await _open(
      tester,
      levels: List.filled(14, 0),
      progress: FakeProgressRepository({
        for (var i = 0; i < 14; i++)
          'id$i': WordProgress(seen: 1000 + i, errors: 100 + i),
      }),
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

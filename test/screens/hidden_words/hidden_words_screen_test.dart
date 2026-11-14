import 'package:acerta/models/word_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

Future<void> _open(
  WidgetTester tester, {
  required FakeProgressRepository progress,
}) async {
  await pumpApp(tester, progress: progress);
  await tapKey(tester, 'home-settings');
  await tapKey(tester, 'settings-hidden');
}

void main() {
  testWidgets('lists the hidden words by text, with the first translation', (
    tester,
  ) async {
    await _open(
      tester,
      progress: FakeProgressRepository({
        'id3': const WordProgress(hidden: true),
        'id1': const WordProgress(hidden: true),
        'id2': const WordProgress(seen: 4),
      }),
    );

    expect(find.text('w1'), findsOneWidget);
    expect(find.text('en1'), findsOneWidget);
    expect(find.text('w3'), findsOneWidget);
    expect(find.text('w2'), findsNothing);
    expect(
      tester.getTopLeft(find.text('w1')).dy,
      lessThan(tester.getTopLeft(find.text('w3')).dy),
    );
    expect(find.text('No hidden words.'), findsNothing);
  });

  testWidgets('Restore brings a word back', (tester) async {
    final progress = FakeProgressRepository({
      'id1': const WordProgress(hidden: true, seen: 2),
      'id3': const WordProgress(hidden: true),
    });
    await _open(tester, progress: progress);
    await tapKey(tester, 'restore-id1');

    expect(progress.of('id1')!.hidden, isFalse);
    expect(progress.of('id1')!.seen, 2);
    expect(find.text('w1'), findsNothing);
    expect(find.text('w3'), findsOneWidget);
  });

  testWidgets('says so when nothing is hidden', (tester) async {
    await _open(tester, progress: FakeProgressRepository());
    expect(find.text('No hidden words.'), findsOneWidget);
  });

  testWidgets('skips a hidden id that is not in the card set', (tester) async {
    await _open(
      tester,
      progress: FakeProgressRepository({
        'gone': const WordProgress(hidden: true),
        'id1': const WordProgress(hidden: true),
      }),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('w1'), findsOneWidget);
    expect(find.byKey(const Key('restore-gone')), findsNothing);
  });

  testWidgets('a lone id that left the card set shows the empty state', (
    tester,
  ) async {
    await _open(
      tester,
      progress: FakeProgressRepository({
        'gone': const WordProgress(hidden: true),
      }),
    );
    expect(find.text('No hidden words.'), findsOneWidget);
  });
}

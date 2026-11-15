// End-to-end test: the real app on a device or emulator, with the real word
// asset and real Hive boxes.
//
//   flutter test integration_test/app_test.dart -d emulator-5554
//
// Or `scripts/e2e.sh`, which also boots the emulator.
//
// This covers what `flutter_test` cannot: a `testWidgets` body runs on a fake
// clock, so a Hive write never completes inside it and the widget tests run on
// fakes. Here the boxes, the asset and the clock are real.
//
// It is ONE test with numbered stages rather than several tests: each stage
// depends on the state the last one left, down to the restart at the end.

import 'package:acerta/app.dart';
import 'package:acerta/main.dart' as app;
import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/pair_round.dart';
import 'package:acerta/models/round_state.dart';
import 'package:acerta/providers/learn_provider.dart';
import 'package:acerta/providers/progress_provider.dart';
import 'package:acerta/providers/reports_provider.dart';
import 'package:acerta/providers/round_provider.dart';
import 'package:acerta/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

/// Pump until [condition] holds or [timeout] passes.
///
/// `pumpAndSettle` is not usable while the words load: the spinner keeps the
/// frame queue busy and it times out even when everything is fine.
Future<void> waitUntil(
  WidgetTester tester,
  bool Function() condition,
  String what, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (condition()) return;
  }
  fail('timed out waiting for: $what');
}

/// Pump until [finder] matches or [timeout] passes.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) => waitUntil(
  tester,
  () => finder.evaluate().isNotEmpty,
  finder.describeMatch(Plurality.one),
  timeout: timeout,
);

/// Scroll [key] into view, tap it and let the frame settle.
Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await waitFor(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// The provider container of the running app.
ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(AcertaApp)));

/// Start the app and wait for the words: the real asset is parsed in an
/// isolate, which takes a few seconds on an emulator.
Future<ProviderContainer> startApp(WidgetTester tester) async {
  await app.main();
  await waitFor(
    tester,
    find.byKey(const Key('start-round')),
    timeout: const Duration(seconds: 120),
  );
  return containerOf(tester);
}

/// Wait for the round being drawn and return it.
Future<PairRound> awaitRound(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await waitUntil(
    tester,
    () => container.read(roundProvider).status == RoundStatus.playing,
    'a playing round',
  );
  return container.read(roundProvider).round!;
}

Future<void> match(WidgetTester tester, RoundPair pair) async {
  await tapKey(tester, 'left-${pair.left}');
  await tapKey(tester, 'right-${pair.right}');
}

String textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a learner plays, changes the settings and comes back', (
    tester,
  ) async {
    // 1. A fresh install: default settings, no progress.
    var container = await startApp(tester);
    expect(
      container.read(progressProvider),
      isEmpty,
      reason: 'the app has data from an earlier run; uninstall it first',
    );
    expect(textOf(tester, 'home-setup'), contains('Up to B1 · 5 pairs'));
    expect(textOf(tester, 'home-setup'), contains('English'));

    // 2. A round, with one wrong tap on the way.
    await tapKey(tester, 'start-round');
    final first = await awaitRound(tester, container);
    expect(first.pairs, hasLength(5));
    expect(first.language, AnswerLanguage.en);
    expect(
      first.pairs.every((p) => p.card.level.index <= Level.b1.index),
      true,
    );

    final missed = first.pairs[0];
    await tapKey(tester, 'left-${missed.left}');
    await tapKey(tester, 'right-${first.pairs[1].right}');
    expect(textOf(tester, 'round-feedback'), 'Wrong pair.');
    for (final pair in first.pairs) {
      await match(tester, pair);
    }

    // 3. The summary, and what the round recorded in the real box.
    await waitFor(tester, find.byKey(const Key('next-round')));
    expect(textOf(tester, 'summary-score'), '4 of 5 right first time');
    expect(find.byKey(Key('missed-${missed.card.id}')), findsOneWidget);
    expect(find.byKey(Key('missed-${first.pairs[1].card.id}')), findsNothing);

    var progress = container.read(progressProvider);
    expect(progress, hasLength(5));
    expect(progress[missed.card.id]!.seen, 2);
    expect(progress[missed.card.id]!.errors, 1);
    expect(progress[missed.card.id]!.correct, 1);
    expect(progress[first.pairs[1].card.id]!.seen, 1);

    // The title adds the first Italian translation of the card when it has
    // one, and stays at two parts when it has none.
    for (final pair in first.pairs) {
      final title = textOf(tester, 'summary-title-${pair.card.id}');
      final it = pair.card.it;
      expect(
        title,
        it.isEmpty
            ? '${pair.left} - ${pair.right}'
            : '${pair.left} - ${pair.right} - ${it.first}',
      );
    }

    // 4. Hide a word from the summary, report another pair, which hides its
    //    word too, and mark a fifth to learn, which leaves it in play.
    final hidden = first.pairs[2].card;
    await tapKey(tester, 'hide-${hidden.id}');
    expect(container.read(progressProvider)[hidden.id]!.hidden, true);
    expect(find.text('Hidden, undo'), findsOneWidget);

    final reportedPair = first.pairs[3];
    final reported = reportedPair.card;
    await tapKey(tester, 'report-${reported.id}');
    expect(container.read(progressProvider)[reported.id]!.hidden, true);
    expect(find.text('Reported, undo'), findsOneWidget);
    expect(find.text('Hidden, undo'), findsNWidgets(2));
    final report = container.read(reportsProvider)[reported.id]!;
    expect(report.right, reportedPair.right);
    expect(report.language, AnswerLanguage.en);
    expect(report.translations, reported.en);

    final toLearn = first.pairs[4].card;
    await tapKey(tester, 'learn-${toLearn.id}');
    expect(container.read(learnProvider).keys, [toLearn.id]);
    expect(find.text('To learn, undo'), findsOneWidget);
    expect(
      container.read(progressProvider)[toLearn.id]?.hidden ?? false,
      false,
    );

    // 5. The next round holds none of the words just played.
    await tapKey(tester, 'next-round');
    final second = await awaitRound(tester, container);
    final firstIds = {for (final pair in first.pairs) pair.card.id};
    expect(second.pairs.where((p) => firstIds.contains(p.card.id)), isEmpty);
    for (final pair in second.pairs) {
      await match(tester, pair);
    }
    await waitFor(tester, find.byKey(const Key('next-round')));
    expect(textOf(tester, 'summary-score'), '5 of 5 right first time');
    await tapKey(tester, 'round-home');
    await waitFor(tester, find.byKey(const Key('start-round')));

    // 6. The progress screen counts the ten words and lists the missed one.
    await tapKey(tester, 'home-progress');
    await waitFor(tester, find.byKey(const Key('progress-total')));
    expect(textOf(tester, 'progress-total'), startsWith('Total: 10 of '));
    expect(find.byKey(Key('missed-${missed.card.id}')), findsOneWidget);
    await tester.pageBack();
    await waitFor(tester, find.byKey(const Key('start-round')));

    // 7. Settings: a lower level cap, Italian answers and medical words off.
    //    Two words are hidden, one of them reported.
    await tapKey(tester, 'home-settings');
    await tapKey(tester, 'level-A2');
    await tapKey(tester, 'language-it');
    await tapKey(tester, 'topic-medical');
    expect(container.read(settingsProvider).offTopics, contains('medical'));
    expect(
      find.descendant(
        of: find.byKey(const Key('settings-hidden')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('settings-reports')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    await tester.pageBack();
    await waitFor(tester, find.byKey(const Key('start-round')));
    expect(textOf(tester, 'home-setup'), contains('Up to A2 · 5 pairs'));
    expect(textOf(tester, 'home-setup'), contains('Italian'));

    await tapKey(tester, 'start-round');
    final italian = await awaitRound(tester, container);
    expect(italian.language, AnswerLanguage.it);
    for (final pair in italian.pairs) {
      expect(pair.card.level.index, lessThanOrEqualTo(Level.a2.index));
      expect(pair.card.it, contains(pair.right));
      expect(pair.card.id, isNot(hidden.id));
      expect(pair.card.id, isNot(reported.id));
      expect(pair.card.topics, isNot(contains('medical')));
    }
    await tester.pageBack();
    await waitFor(tester, find.byKey(const Key('start-round')));

    // 8. Restart: unmount the app, close the boxes, start `main` again. The
    //    new app has a new container and reads everything back from the files.
    await tester.pumpWidget(const SizedBox.shrink());
    await Hive.close();
    final restarted = await startApp(tester);
    expect(identical(restarted, container), false);
    container = restarted;

    expect(container.read(settingsProvider).maxLevel, Level.a2);
    expect(container.read(settingsProvider).answerLanguage, AnswerLanguage.it);
    expect(container.read(settingsProvider).pairsPerRound, 5);
    expect(container.read(settingsProvider).offTopics, contains('medical'));
    expect(textOf(tester, 'home-setup'), contains('Up to A2 · 5 pairs'));

    progress = container.read(progressProvider);
    expect(progress, hasLength(10));
    expect(progress[missed.card.id]!.seen, 2);
    expect(progress[missed.card.id]!.errors, 1);
    expect(progress[missed.card.id]!.lastSeenAt, isNotNull);
    expect(progress[hidden.id]!.hidden, true);
    expect(progress[reported.id]!.hidden, true);
    final reports = container.read(reportsProvider);
    expect(reports.keys, [reported.id]);
    expect(reports[reported.id]!.text, reported.text);
    expect(reports[reported.id]!.right, reportedPair.right);
    expect(reports[reported.id]!.reportedAt, isNotNull);

    expect(container.read(learnProvider).keys, [toLearn.id]);
    expect(container.read(learnProvider)[toLearn.id], isNotNull);

    // 9. The hidden words are still listed, and can be brought back. A
    //    reported word comes back too, and its report stays listed until it
    //    is removed.
    await tapKey(tester, 'home-settings');
    await tapKey(tester, 'settings-hidden');
    await tapKey(tester, 'restore-${hidden.id}');
    await tapKey(tester, 'restore-${reported.id}');
    await waitFor(tester, find.text('No hidden words.'));
    expect(container.read(progressProvider)[hidden.id]!.hidden, false);
    expect(container.read(progressProvider)[reported.id]!.hidden, false);
    expect(container.read(reportsProvider), hasLength(1));

    await tester.pageBack();
    await tapKey(tester, 'settings-reports');
    expect(find.byKey(Key('report-row-${reported.id}')), findsOneWidget);
    await tapKey(tester, 'report-remove-${reported.id}');
    await waitFor(tester, find.text('No reported pairs.'));
    expect(container.read(reportsProvider), isEmpty);

    // The marked word is listed, and Remove empties the list.
    await tester.pageBack();
    await tapKey(tester, 'settings-learn');
    expect(find.byKey(Key('learn-row-${toLearn.id}')), findsOneWidget);
    await tapKey(tester, 'learn-remove-${toLearn.id}');
    await waitFor(tester, find.text('No words to learn.'));
    expect(container.read(learnProvider), isEmpty);
  });
}

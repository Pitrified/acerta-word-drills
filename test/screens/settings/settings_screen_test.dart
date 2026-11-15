import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/word_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

Future<void> _openSettings(
  WidgetTester tester, {
  FakeProgressRepository? progress,
  FakeReportRepository? reports,
  FakeLearnRepository? learn,
  FakeSettingsRepository? settings,
  List<int>? levels,
  List<List<String>?> it = const [],
  List<List<String>> topics = const [],
}) async {
  await pumpApp(
    tester,
    progress: progress,
    reports: reports,
    learn: learn,
    settings: settings,
    cards: levels == null
        ? null
        : cardRepositoryOf([
            for (var i = 0; i < levels.length; i++)
              fakeCard(
                i,
                level: Level.values[levels[i]],
                it: i < it.length ? it[i] : null,
                topics: i < topics.length ? topics[i] : const [],
              ),
          ]),
  );
  await tapKey(tester, 'home-settings');
}

void main() {
  testWidgets('each level option writes the level cap', (tester) async {
    final settings = FakeSettingsRepository();
    await _openSettings(tester, settings: settings);
    for (final level in Level.values) {
      await tapKey(tester, 'level-${level.label}');
      expect(settings.read().maxLevel, level);
    }
    final chip = tester.widget<ChoiceChip>(find.byKey(const Key('level-C2')));
    expect(chip.selected, isTrue);
  });

  testWidgets('the level cap shown is the stored one', (tester) async {
    await _openSettings(
      tester,
      settings: FakeSettingsRepository(const DrillSettings(maxLevel: Level.a2)),
    );
    ChoiceChip chip(String key) =>
        tester.widget<ChoiceChip>(find.byKey(Key(key)));
    expect(chip('level-A2').selected, isTrue);
    expect(chip('level-B1').selected, isFalse);
  });

  testWidgets('the slider writes the pairs per round and shows it', (
    tester,
  ) async {
    final settings = FakeSettingsRepository();
    await _openSettings(tester, settings: settings);
    expect(find.byKey(const Key('settings-pairs-value')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('settings-pairs-value'))).data,
      '5',
    );
    final slider = tester.widget<Slider>(
      find.byKey(const Key('settings-pairs')),
    );
    expect(slider.divisions, 5);
    expect(slider.min, minPairsPerRound);
    expect(slider.max, maxPairsPerRound);

    await tester.drag(
      find.byKey(const Key('settings-pairs')),
      const Offset(2000, 0),
    );
    await tester.pumpAndSettle();
    expect(settings.read().pairsPerRound, 8);
    expect(
      tester.widget<Text>(find.byKey(const Key('settings-pairs-value'))).data,
      '8',
    );

    await tester.drag(
      find.byKey(const Key('settings-pairs')),
      const Offset(-2000, 0),
    );
    await tester.pumpAndSettle();
    expect(settings.read().pairsPerRound, 3);
  });

  testWidgets('each answer language option writes the language', (
    tester,
  ) async {
    final settings = FakeSettingsRepository();
    await _openSettings(tester, settings: settings);
    await tapKey(tester, 'language-it');
    expect(settings.read().answerLanguage, AnswerLanguage.it);
    await tapKey(tester, 'language-en');
    expect(settings.read().answerLanguage, AnswerLanguage.en);
  });

  testWidgets('says how many words the level cap has in the language', (
    tester,
  ) async {
    await _openSettings(
      tester,
      // Three A1 words (one without Italian), one A2, one C1.
      levels: [0, 0, 0, 1, 4],
      it: [
        ['a'],
        [],
        ['b'],
        ['c'],
        ['d'],
      ],
      settings: FakeSettingsRepository(const DrillSettings(maxLevel: Level.a2)),
    );
    String line() => tester
        .widget<Text>(find.byKey(const Key('settings-language-count')))
        .data!;
    expect(line(), '4 words up to A2 have an English translation.');

    await tapKey(tester, 'language-it');
    expect(line(), '3 words up to A2 have an Italian translation.');

    await tapKey(tester, 'level-C2');
    expect(line(), '4 words up to C2 have an Italian translation.');
  });

  group('topics', () {
    // Three medical words (one also about people), two about people, one
    // with no topic: medical 3, people 3 ties by name.
    const topics = [
      ['medical'],
      ['medical'],
      ['medical', 'people'],
      ['people'],
      ['people'],
      <String>[],
    ];

    Future<FakeSettingsRepository> open(
      WidgetTester tester, {
      Set<String> off = const {},
    }) async {
      final settings = FakeSettingsRepository(DrillSettings(offTopics: off));
      await _openSettings(
        tester,
        levels: [0, 0, 0, 0, 0, 0],
        topics: topics,
        settings: settings,
      );
      return settings;
    }

    String label(WidgetTester tester, String key) => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(Text),
          ),
        )
        .data!;

    testWidgets('a chip per topic with its count, most words first', (
      tester,
    ) async {
      await open(tester);
      await tester.ensureVisible(find.byKey(const Key('topic-medical')));
      expect(label(tester, 'topic-medical'), 'Medical 3');
      expect(label(tester, 'topic-people'), 'People 3');
      expect(
        tester.getTopLeft(find.byKey(const Key('topic-medical'))).dx,
        lessThan(tester.getTopLeft(find.byKey(const Key('topic-people'))).dx),
      );
      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('topic-medical')))
            .selected,
        isTrue,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('settings-topics-note'))).data,
        'Words with no topic are always included.',
      );
    });

    testWidgets('a chip toggles its topic and writes it', (tester) async {
      final settings = await open(tester);
      await tapKey(tester, 'topic-medical');
      expect(settings.read().offTopics, {'medical'});
      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('topic-medical')))
            .selected,
        isFalse,
      );
      await tapKey(tester, 'topic-medical');
      expect(settings.read().offTopics, isEmpty);
    });

    testWidgets('the stored off topics show as not selected', (tester) async {
      await open(tester, off: {'people'});
      await tester.ensureVisible(find.byKey(const Key('topic-people')));
      FilterChip chip(String key) =>
          tester.widget<FilterChip>(find.byKey(Key(key)));
      expect(chip('topic-people').selected, isFalse);
      expect(chip('topic-medical').selected, isTrue);
    });

    testWidgets('the count line follows the topics', (tester) async {
      await open(tester);
      String line() => tester
          .widget<Text>(find.byKey(const Key('settings-language-count')))
          .data!;
      expect(line(), '6 words up to B1 have an English translation.');
      await tapKey(tester, 'topic-medical');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapKey(tester, 'home-settings');
      // Medical off leaves the two people-only words and the one with none.
      expect(line(), '3 words up to B1 have an English translation.');
    });
  });

  testWidgets('the hidden entry shows the count and opens the list', (
    tester,
  ) async {
    await _openSettings(
      tester,
      progress: FakeProgressRepository({
        'id1': const WordProgress(hidden: true),
        'id2': const WordProgress(hidden: true, seen: 3),
        'id3': const WordProgress(seen: 1),
      }),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('settings-hidden')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    await tapKey(tester, 'settings-hidden');
    expect(find.text('Hidden words'), findsOneWidget);
    expect(find.byKey(const Key('restore-id1')), findsOneWidget);
  });

  group('reset progress', () {
    late FakeProgressRepository progress;

    setUp(() {
      progress = FakeProgressRepository({
        'id1': const WordProgress(seen: 3, correct: 2, errors: 1),
        'id2': const WordProgress(seen: 2, errors: 2, hidden: true),
      });
    });

    testWidgets('Cancel leaves the progress alone', (tester) async {
      await _openSettings(tester, progress: progress);
      await tapKey(tester, 'settings-reset');
      expect(
        find.textContaining('counts of every word are forgotten'),
        findsOneWidget,
      );
      expect(find.textContaining('Hidden words stay hidden'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reset-confirm')), findsNothing);
      expect(progress.of('id1')!.seen, 3);
      expect(progress.of('id2')!.errors, 2);
      expect(find.text('Progress reset'), findsNothing);
    });

    testWidgets('Reset forgets the counts and keeps the hidden words', (
      tester,
    ) async {
      await _openSettings(tester, progress: progress);
      await tapKey(tester, 'settings-reset');
      await tapKey(tester, 'reset-confirm');

      expect(progress.of('id1'), isNull);
      expect(progress.of('id2'), const WordProgress(hidden: true));
      expect(find.text('Progress reset'), findsOneWidget);
    });
  });

  testWidgets('Reported pairs shows the count and opens the list', (
    tester,
  ) async {
    await pumpApp(
      tester,
      reports: FakeReportRepository([fakeReport(1), fakeReport(2)]),
    );
    await tapKey(tester, 'home-settings');
    expect(
      find.descendant(
        of: find.byKey(const Key('settings-reports')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    await tapKey(tester, 'settings-reports');
    expect(find.widgetWithText(AppBar, 'Reported pairs'), findsOneWidget);
    expect(find.byKey(const Key('report-row-id1')), findsOneWidget);
  });

  testWidgets('Reset progress keeps the reported pairs', (tester) async {
    final reports = FakeReportRepository([fakeReport(1)]);
    final progress = FakeProgressRepository({
      'id1': const WordProgress(seen: 1, hidden: true),
      'id2': const WordProgress(seen: 2),
    });
    await _openSettings(tester, progress: progress, reports: reports);
    await tapKey(tester, 'settings-reset');
    await tapKey(tester, 'reset-confirm');
    expect(progress.of('id2'), isNull);
    expect(reports.all.keys, ['id1']);
    expect(
      find.descendant(
        of: find.byKey(const Key('settings-reports')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Words to learn shows the count and opens the list', (
    tester,
  ) async {
    await pumpApp(
      tester,
      learn: FakeLearnRepository({'id1': fixedNow, 'id2': fixedNow}),
    );
    await tapKey(tester, 'home-settings');
    expect(
      find.descendant(
        of: find.byKey(const Key('settings-learn')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    await tapKey(tester, 'settings-learn');
    expect(find.widgetWithText(AppBar, 'Words to learn'), findsOneWidget);
    expect(find.byKey(const Key('learn-row-id1')), findsOneWidget);
  });

  testWidgets('Reset progress keeps the words to learn', (tester) async {
    final learn = FakeLearnRepository({'id1': fixedNow});
    final progress = FakeProgressRepository({
      'id1': const WordProgress(seen: 1, hidden: true),
      'id2': const WordProgress(seen: 2),
    });
    await _openSettings(tester, progress: progress, learn: learn);
    await tapKey(tester, 'settings-reset');
    await tapKey(tester, 'reset-confirm');
    expect(progress.of('id2'), isNull);
    expect(learn.all.keys, ['id1']);
    expect(
      find.descendant(
        of: find.byKey(const Key('settings-learn')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('fits a 320 x 568 phone', (tester) async {
    useSmallPhone(tester);
    await _openSettings(tester);
    expect(tester.takeException(), isNull);
    for (final level in Level.values) {
      final chip = find.byKey(Key('level-${level.label}'));
      expect(tester.getTopRight(chip).dx, lessThanOrEqualTo(320));
    }
    await tester.ensureVisible(find.byKey(const Key('settings-reset')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'scrolled to the end, the last row ends above the navigation bar',
    (tester) async {
      // A tall phone with a system navigation bar of 48 at the bottom, and
      // enough topics for the screen to scroll.
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);

      await _openSettings(
        tester,
        levels: List.filled(30, 0),
        topics: [
          for (var i = 0; i < 30; i++) ['topic$i'],
        ],
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -5000),
      );
      await tester.pumpAndSettle();

      final reset = tester.getRect(find.byKey(const Key('settings-reset')));
      expect(reset.bottom, lessThanOrEqualTo(915 - 48));
    },
  );
}

import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/word_progress.dart';
import 'package:acerta/providers/cards_provider.dart';
import 'package:acerta/providers/progress_provider.dart';
import 'package:acerta/providers/settings_provider.dart';
import 'package:acerta/providers/words_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

/// A container on the cards [cardList], with the words already loaded.
Future<ProviderContainer> _container({
  required List<int> levels,
  Map<String, WordProgress> progress = const {},
  DrillSettings settings = const DrillSettings(),
  List<List<String>?> it = const [],
}) async {
  final cards = [
    for (var i = 0; i < levels.length; i++)
      fakeCard(
        i,
        level: Level.values[levels[i]],
        it: i < it.length ? it[i] : null,
      ),
  ];
  final container = ProviderContainer(
    overrides: roundOverrides(
      cards: cardRepositoryOf(cards),
      progress: FakeProgressRepository(progress),
      settings: FakeSettingsRepository(settings),
    ),
  );
  addTearDown(container.dispose);
  await container.read(cardRepositoryProvider.future);
  return container;
}

void main() {
  group('poolSizesProvider', () {
    test('counts the pool of each language at the level cap', () async {
      final container = await _container(
        levels: [0, 0, 1, 2, 3],
        it: [
          ['a'],
          [],
          ['b'],
          ['c'],
          ['d'],
        ],
        settings: const DrillSettings(maxLevel: Level.a2),
      );
      final sizes = container.read(poolSizesProvider).requireValue;
      expect(sizes[AnswerLanguage.en], 3);
      expect(sizes[AnswerLanguage.it], 2);
    });

    test('follows the level cap', () async {
      final container = await _container(levels: [0, 1, 2, 3, 4, 5]);
      expect(
        container.read(poolSizesProvider).requireValue[AnswerLanguage.en],
        3,
      );
      await container.read(settingsProvider.notifier).setMaxLevel(Level.c2);
      expect(
        container.read(poolSizesProvider).requireValue[AnswerLanguage.en],
        6,
      );
    });
  });

  group('hiddenWordsProvider', () {
    test('lists the hidden words sorted by text', () async {
      final container = await _container(
        levels: [0, 0, 0, 0],
        progress: {
          'id3': const WordProgress(hidden: true),
          'id1': const WordProgress(hidden: true, seen: 2),
          'id2': const WordProgress(seen: 1),
        },
      );
      final words = container.read(hiddenWordsProvider).requireValue;
      expect(words.map((c) => c.text), ['w1', 'w3']);
      expect(container.read(hiddenCountProvider), 2);
    });

    test('skips an id that is not in the card set', () async {
      final container = await _container(
        levels: [0, 0],
        progress: {
          'gone': const WordProgress(hidden: true),
          'id1': const WordProgress(hidden: true),
        },
      );
      final words = container.read(hiddenWordsProvider).requireValue;
      expect(words.map((c) => c.id), ['id1']);
      expect(container.read(hiddenCountProvider), 1);
    });

    test('follows a word being hidden and restored', () async {
      final container = await _container(levels: [0, 0]);
      expect(container.read(hiddenWordsProvider).requireValue, isEmpty);
      final notifier = container.read(progressProvider.notifier);
      await notifier.setHidden('id0', hidden: true);
      expect(container.read(hiddenCountProvider), 1);
      await notifier.setHidden('id0', hidden: false);
      expect(container.read(hiddenCountProvider), 0);
    });
  });

  group('levelProgressProvider', () {
    test('counts the seen words and the words of each exact level', () async {
      final container = await _container(
        levels: [0, 0, 0, 1, 2, 5],
        progress: {
          'id0': const WordProgress(seen: 3),
          'id1': const WordProgress(seen: 1),
          'id3': const WordProgress(seen: 1),
        },
      );
      final levels = container.read(levelProgressProvider).requireValue;
      expect(levels.map((l) => l.level), Level.values);
      expect(levels.map((l) => l.seen), [2, 1, 0, 0, 0, 0]);
      expect(levels.map((l) => l.total), [3, 1, 1, 0, 0, 1]);
    });

    test('ignores a record that only holds the hidden flag', () async {
      final container = await _container(
        levels: [0, 0],
        progress: {
          'id0': const WordProgress(hidden: true),
          'id1': const WordProgress(seen: 1),
        },
      );
      final levels = container.read(levelProgressProvider).requireValue;
      expect(levels.first.seen, 1);
    });

    test('skips an id that is not in the card set', () async {
      final container = await _container(
        levels: [0],
        progress: {'gone': const WordProgress(seen: 4)},
      );
      final levels = container.read(levelProgressProvider).requireValue;
      expect(levels.map((l) => l.seen), everyElement(0));
    });
  });

  group('mostMissedProvider', () {
    test('sorts by errors descending and breaks ties by text', () async {
      final container = await _container(
        levels: [0, 0, 0, 0, 0],
        progress: {
          'id1': const WordProgress(seen: 4, errors: 2),
          'id2': const WordProgress(seen: 3, errors: 2),
          'id3': const WordProgress(seen: 9, errors: 5),
          'id4': const WordProgress(seen: 9, errors: 1),
          'id0': const WordProgress(seen: 9),
        },
      );
      final words = container.read(mostMissedProvider).requireValue;
      expect(words.map((w) => w.card.text), ['w3', 'w1', 'w2', 'w4']);
      expect(words.first.progress.errors, 5);
    });

    test('keeps the ten words with the most errors', () async {
      final container = await _container(
        levels: List.filled(14, 0),
        progress: {
          for (var i = 0; i < 14; i++)
            'id$i': WordProgress(seen: 20, errors: i + 1),
        },
      );
      final words = container.read(mostMissedProvider).requireValue;
      expect(words, hasLength(mostMissedLimit));
      expect(words.first.progress.errors, 14);
      expect(words.last.progress.errors, 5);
    });

    test('skips an id that is not in the card set', () async {
      final container = await _container(
        levels: [0],
        progress: {
          'gone': const WordProgress(seen: 9, errors: 9),
          'id0': const WordProgress(seen: 1, errors: 1),
        },
      );
      final words = container.read(mostMissedProvider).requireValue;
      expect(words.map((w) => w.card.id), ['id0']);
    });

    test('is empty with no errors', () async {
      final container = await _container(
        levels: [0],
        progress: {'id0': const WordProgress(seen: 1)},
      );
      expect(container.read(mostMissedProvider).requireValue, isEmpty);
    });
  });
}

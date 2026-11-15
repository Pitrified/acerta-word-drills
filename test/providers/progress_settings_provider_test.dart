import 'dart:io';

import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/word_progress.dart';
import 'package:acerta/providers/progress_provider.dart';
import 'package:acerta/providers/settings_provider.dart';
import 'package:acerta/services/progress/progress_repository.dart';
import 'package:acerta/services/settings/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

final _when = DateTime.utc(2026, 1, 1, 10);

void main() {
  late Directory dir;
  late ProviderContainer container;
  late ProgressRepository progressRepository;
  late SettingsRepository settingsRepository;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('acerta_providers');
    Hive.init(dir.path);
    progressRepository = await ProgressRepository.open();
    settingsRepository = await SettingsRepository.open();
    container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(progressRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  group('progressProvider', () {
    test('starts from the repository', () async {
      await progressRepository.setHidden('a', hidden: true);
      final other = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(progressRepository),
        ],
      );
      addTearDown(other.dispose);
      expect(other.read(progressProvider).keys, ['a']);
    });

    test('record updates the state and the repository', () async {
      final notifier = container.read(progressProvider.notifier);
      expect(container.read(progressProvider), isEmpty);
      await notifier.record('a', correct: true, when: _when);
      expect(
        container.read(progressProvider)['a'],
        WordProgress(seen: 1, correct: 1, lastSeenAt: _when),
      );
      expect(progressRepository.of('a')!.seen, 1);
    });

    test('listeners see a new map after each change', () async {
      final notifier = container.read(progressProvider.notifier);
      final seen = <Map<String, WordProgress>>[];
      container.listen(progressProvider, (_, next) => seen.add(next));
      await notifier.record('a', correct: false, when: _when);
      await notifier.setHidden('a', hidden: true);
      await notifier.resetCounts();
      expect(seen, hasLength(3));
      expect(seen[0]['a']!.errors, 1);
      expect(seen[1]['a']!.hidden, isTrue);
      expect(seen[2]['a'], const WordProgress(hidden: true));
      expect(identical(seen[0], seen[1]), isFalse);
    });

    test('resetCounts drops a word that is not hidden', () async {
      final notifier = container.read(progressProvider.notifier);
      await notifier.record('a', correct: true, when: _when);
      await notifier.resetCounts();
      expect(container.read(progressProvider), isEmpty);
    });

    test('reading it without an override throws a named error', () {
      final bare = ProviderContainer();
      addTearDown(bare.dispose);
      expect(
        () => bare.read(progressProvider),
        throwsA(
          predicate(
            (Object e) => e.toString().contains('ProviderNotOverriddenError'),
          ),
        ),
      );
    });
  });

  group('settingsProvider', () {
    test('starts from the repository', () {
      expect(container.read(settingsProvider).pairsPerRound, 5);
    });

    test('each setter changes the state and writes through', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setMaxLevel(Level.c2);
      expect(container.read(settingsProvider).maxLevel, Level.c2);
      await notifier.setPairsPerRound(8);
      expect(container.read(settingsProvider).pairsPerRound, 8);
      await notifier.setAnswerLanguage(AnswerLanguage.it);
      expect(
        container.read(settingsProvider).answerLanguage,
        AnswerLanguage.it,
      );
      expect(settingsRepository.read(), container.read(settingsProvider));
    });

    test('setTopicOn turns a topic off and on and writes through', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setTopicOn('medical', false);
      await notifier.setTopicOn('people', false);
      await notifier.setTopicOn('medical', false);
      expect(container.read(settingsProvider).offTopics, {'medical', 'people'});
      expect(settingsRepository.read().offTopics, {'medical', 'people'});
      await notifier.setTopicOn('medical', true);
      expect(container.read(settingsProvider).offTopics, {'people'});
      expect(settingsRepository.read().offTopics, {'people'});
    });
  });
}

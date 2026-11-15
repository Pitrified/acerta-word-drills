import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/providers/round_provider.dart';
import 'package:acerta/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  test('raising the level cap changes the words of the next round', () async {
    final container = ProviderContainer(
      overrides: roundOverrides(
        cards: cardRepositoryOf([
          for (var i = 0; i < 4; i++) fakeCard(i),
          for (var i = 4; i < 24; i++) fakeCard(i, level: Level.c1),
        ]),
        progress: FakeProgressRepository(),
        settings: FakeSettingsRepository(
          const DrillSettings(maxLevel: Level.a1, pairsPerRound: 3),
        ),
      ),
    );
    addTearDown(container.dispose);
    final rounds = container.read(roundProvider.notifier);

    await rounds.start();
    final under = container.read(roundProvider).round!.pairs;
    expect(under.map((p) => p.card.level), everyElement(Level.a1));

    await container.read(settingsProvider.notifier).setMaxLevel(Level.c1);
    await rounds.start();
    final over = container.read(roundProvider).round!.pairs;
    expect(over.map((p) => p.card.level), contains(Level.c1));
  });

  test('a round with medical off draws no medical card', () async {
    final container = ProviderContainer(
      overrides: roundOverrides(
        cards: cardRepositoryOf([
          for (var i = 0; i < 10; i++) fakeCard(i, topics: ['medical']),
          for (var i = 10; i < 20; i++) fakeCard(i, topics: ['medical', 'x']),
          for (var i = 20; i < 40; i++) fakeCard(i),
        ]),
        progress: FakeProgressRepository(),
        settings: FakeSettingsRepository(const DrillSettings(pairsPerRound: 5)),
      ),
    );
    addTearDown(container.dispose);
    final rounds = container.read(roundProvider.notifier);
    await container
        .read(settingsProvider.notifier)
        .setTopicOn('medical', false);
    for (var i = 0; i < 10; i++) {
      await rounds.start();
      final pairs = container.read(roundProvider).round!.pairs;
      expect(pairs.expand((p) => p.card.topics), isNot(contains('medical')));
    }
  });
}

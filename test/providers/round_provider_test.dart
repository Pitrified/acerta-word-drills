import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/round_state.dart';
import 'package:acerta/providers/progress_provider.dart';
import 'package:acerta/providers/round_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late FakeProgressRepository progress;
  late ProviderContainer container;
  late RoundNotifier notifier;

  ProviderContainer containerOf({
    int cards = 12,
    DrillSettings settings = const DrillSettings(),
  }) {
    final made = ProviderContainer(
      overrides: roundOverrides(
        cards: fakeCardRepository(cards),
        progress: progress,
        settings: FakeSettingsRepository(settings),
      ),
    );
    addTearDown(made.dispose);
    return made;
  }

  RoundState read() => container.read(roundProvider);

  Future<void> startRound() async {
    notifier = container.read(roundProvider.notifier);
    await notifier.start();
  }

  setUp(() async {
    progress = FakeProgressRepository();
    container = containerOf();
    await startRound();
  });

  group('start', () {
    test('gives a playing round of the size in the settings', () {
      expect(read().status, RoundStatus.playing);
      expect(read().round!.pairs, hasLength(5));
      expect(read().matchedLeft, isEmpty);
      expect(read().missedCardIds, isEmpty);
    });

    test('follows the pairs per round setting', () async {
      container = containerOf(settings: const DrillSettings(pairsPerRound: 8));
      await startRound();
      expect(read().round!.pairs, hasLength(8));
    });

    test('with too few words gives notEnoughWords', () async {
      container = containerOf(cards: 1);
      await startRound();
      expect(read().status, RoundStatus.notEnoughWords);
      expect(read().round, isNull);
    });

    test('never puts a hidden word in a round', () async {
      await progress.setHidden('id0', hidden: true);
      await progress.setHidden('id1', hidden: true);
      container = containerOf();
      for (var i = 0; i < 30; i++) {
        await startRound();
        final lefts = read().round!.pairs.map((p) => p.left);
        expect(lefts, isNot(contains('w0')));
        expect(lefts, isNot(contains('w1')));
      }
    });

    test('a second round shares no card with the one just played', () async {
      final first = read().round!.pairs.map((p) => p.card.id).toSet();
      for (final pair in read().round!.pairs) {
        await notifier.tapLeft(pair.left);
        await notifier.tapRight(pair.right);
      }
      expect(read().status, RoundStatus.finished);
      await startRound();
      final second = read().round!.pairs.map((p) => p.card.id).toSet();
      expect(second.intersection(first), isEmpty);
      expect(read().matchedLeft, isEmpty);
    });
  });

  group('taps', () {
    test('left then right grades the pair', () async {
      final pair = read().round!.pairs.first;
      await notifier.tapLeft(pair.left);
      expect(read().selectedLeft, pair.left);
      await notifier.tapRight(pair.right);
      expect(read().matchedLeft, {pair.left});
    });

    test('right then left grades the pair', () async {
      final pair = read().round!.pairs.first;
      await notifier.tapRight(pair.right);
      expect(read().selectedRight, pair.right);
      await notifier.tapLeft(pair.left);
      expect(read().matchedLeft, {pair.left});
    });

    test('a correct tap locks the pair and records correct', () async {
      final pair = read().round!.pairs.first;
      await notifier.tapLeft(pair.left);
      await notifier.tapRight(pair.right);
      expect(read().matchedLeft, {pair.left});
      expect(read().matchedRight, {pair.right});
      expect(read().selectedLeft, isNull);
      expect(read().selectedRight, isNull);
      expect(read().feedback, isNull);
      expect(read().status, RoundStatus.playing);
      final saved = progress.of(pair.card.id)!;
      expect(saved.correct, 1);
      expect(saved.errors, 0);
      expect(saved.lastSeenAt, fixedNow);
      expect(container.read(progressProvider)[pair.card.id], saved);
    });

    test('a wrong tap marks the pair and records an error', () async {
      final pairs = read().round!.pairs;
      await notifier.tapLeft(pairs[0].left);
      await notifier.tapRight(pairs[1].right);
      final state = read();
      expect(state.wrongLeft, pairs[0].left);
      expect(state.wrongRight, pairs[1].right);
      expect(state.feedback, 'Wrong pair.');
      expect(state.missedCardIds, {pairs[0].card.id});
      expect(state.selectedLeft, isNull);
      expect(state.selectedRight, isNull);
      expect(state.matchedLeft, isEmpty);
      final saved = progress.of(pairs[0].card.id)!;
      expect(saved.errors, 1);
      expect(saved.correct, 0);
      expect(progress.of(pairs[1].card.id), isNull);
    });

    test('a wrong pair stays playable', () async {
      final pairs = read().round!.pairs;
      await notifier.tapLeft(pairs[0].left);
      await notifier.tapRight(pairs[1].right);
      await notifier.tapLeft(pairs[0].left);
      await notifier.tapRight(pairs[0].right);
      expect(read().matchedLeft, {pairs[0].left});
      expect(read().missedCardIds, {pairs[0].card.id});
    });

    test('the state changes before the progress is written', () async {
      final pair = read().round!.pairs.first;
      await notifier.tapLeft(pair.left);
      final pending = notifier.tapRight(pair.right);
      expect(read().matchedLeft, {pair.left});
      await pending;
    });

    test('the decoy tapped for its own word explains itself', () async {
      final round = read().round!;
      final decoy = round.decoys.single;
      await notifier.tapLeft(decoy.left);
      await notifier.tapRight(decoy.text);
      expect(read().feedback, 'False friend! ${decoy.note}');
      expect(read().wrongRight, decoy.text);
      final card = round.pairs.firstWhere((p) => p.left == decoy.left).card;
      expect(read().missedCardIds, {card.id});
      expect(progress.of(card.id)!.errors, 1);
    });

    test('the decoy tapped for another word is a plain wrong pair', () async {
      final round = read().round!;
      final decoy = round.decoys.single;
      final other = round.pairs.firstWhere((p) => p.left != decoy.left);
      await notifier.tapLeft(other.left);
      await notifier.tapRight(decoy.text);
      expect(read().feedback, 'Wrong pair.');
    });

    test('a matched word ignores taps', () async {
      final pairs = read().round!.pairs;
      await notifier.tapLeft(pairs[0].left);
      await notifier.tapRight(pairs[0].right);
      final before = read();
      await notifier.tapLeft(pairs[0].left);
      await notifier.tapRight(pairs[0].right);
      expect(read(), before);
      expect(progress.of(pairs[0].card.id)!.seen, 1);
    });

    test('a matched word ignores a tap while a wrong mark shows', () async {
      final pairs = read().round!.pairs;
      await notifier.tapLeft(pairs[0].left);
      await notifier.tapRight(pairs[0].right);
      await notifier.tapLeft(pairs[1].left);
      await notifier.tapRight(pairs[2].right);
      final before = read();
      await notifier.tapLeft(pairs[0].left);
      expect(read(), before);
    });

    test('tapping the selected word deselects it', () async {
      final pair = read().round!.pairs.first;
      await notifier.tapLeft(pair.left);
      await notifier.tapLeft(pair.left);
      expect(read().selectedLeft, isNull);
      await notifier.tapRight(pair.right);
      await notifier.tapRight(pair.right);
      expect(read().selectedRight, isNull);
      expect(progress.all, isEmpty);
    });

    test('tapping another word of the same side moves the selection', () async {
      final pairs = read().round!.pairs;
      await notifier.tapLeft(pairs[0].left);
      await notifier.tapLeft(pairs[1].left);
      expect(read().selectedLeft, pairs[1].left);
    });

    test('the next tap clears the wrong mark and the feedback', () async {
      final pairs = read().round!.pairs;
      await notifier.tapLeft(pairs[0].left);
      await notifier.tapRight(pairs[1].right);
      expect(read().wrongLeft, isNotNull);
      await notifier.tapLeft(pairs[2].left);
      expect(read().wrongLeft, isNull);
      expect(read().wrongRight, isNull);
      expect(read().feedback, isNull);
      expect(read().selectedLeft, pairs[2].left);
    });

    test('the round finishes when every pair is locked', () async {
      final pairs = read().round!.pairs;
      for (final pair in pairs.take(pairs.length - 1)) {
        await notifier.tapLeft(pair.left);
        await notifier.tapRight(pair.right);
        expect(read().status, RoundStatus.playing);
      }
      final last = pairs.last;
      await notifier.tapLeft(last.left);
      await notifier.tapRight(last.right);
      expect(read().status, RoundStatus.finished);
      expect(read().matchedLeft, pairs.map((p) => p.left).toSet());
      expect(read().round, isNotNull);
    });

    test('taps outside a playing round do nothing', () async {
      final pair = read().round!.pairs.first;
      for (final p in read().round!.pairs) {
        await notifier.tapLeft(p.left);
        await notifier.tapRight(p.right);
      }
      final finished = read();
      await notifier.tapLeft(pair.left);
      await notifier.tapRight('anything');
      expect(read(), finished);

      container = containerOf(cards: 1);
      await startRound();
      await notifier.tapLeft('w0');
      expect(read().status, RoundStatus.notEnoughWords);
      expect(read().selectedLeft, isNull);
    });
  });
}

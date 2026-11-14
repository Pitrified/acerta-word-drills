import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/round_state.dart';
import '../services/pair_matching/pair_matching.dart';
import '../services/selection/selection.dart';
import 'cards_provider.dart';
import 'clock_provider.dart';
import 'progress_provider.dart';
import 'settings_provider.dart';

/// The round on screen, and the finished one until the next starts.
final roundProvider = NotifierProvider<RoundNotifier, RoundState>(
  RoundNotifier.new,
);

/// Draws a round, grades the taps and records them in the progress.
class RoundNotifier extends Notifier<RoundState> {
  @override
  RoundState build() => const RoundState();

  /// Draws and builds a round from the current settings and progress.
  ///
  /// A hidden word has weight 0 in [computeWeight], so the draw never
  /// returns it and the pool is not filtered again here.
  Future<void> start() async {
    state = const RoundState();
    final cards = await ref.read(cardRepositoryProvider.future);
    final settings = ref.read(settingsProvider);
    final progress = ref.read(progressProvider);
    final now = ref.read(clockProvider)();
    final random = ref.read(randomProvider);

    final pool = cards.pool(
      maxLevel: settings.maxLevel,
      language: settings.answerLanguage,
    );
    final drawn = selectCards(
      pool,
      progress,
      settings.pairsPerRound + pairSpares,
      random: random,
      now: now,
    );
    final round = buildRound(
      drawn,
      language: settings.answerLanguage,
      numPairs: settings.pairsPerRound,
      random: random,
    );
    state = round == null
        ? const RoundState(status: RoundStatus.notEnoughWords)
        : RoundState(status: RoundStatus.playing, round: round);
  }

  /// Taps the Portuguese word [left].
  Future<void> tapLeft(String left) {
    final current = state;
    if (current.status != RoundStatus.playing) return Future.value();
    if (current.matchedLeft.contains(left)) return Future.value();
    final cleared = _cleared(current);
    if (current.selectedLeft == left) {
      state = cleared.copyWith(selectedLeft: null);
      return Future.value();
    }
    state = cleared.copyWith(selectedLeft: left);
    return _gradeIfPaired();
  }

  /// Taps the right word [right].
  Future<void> tapRight(String right) {
    final current = state;
    if (current.status != RoundStatus.playing) return Future.value();
    if (current.matchedRight.contains(right)) return Future.value();
    final cleared = _cleared(current);
    if (current.selectedRight == right) {
      state = cleared.copyWith(selectedRight: null);
      return Future.value();
    }
    state = cleared.copyWith(selectedRight: right);
    return _gradeIfPaired();
  }

  /// The state without the wrong mark and its feedback.
  RoundState _cleared(RoundState from) =>
      from.copyWith(wrongLeft: null, wrongRight: null, feedback: null);

  Future<void> _gradeIfPaired() async {
    final current = state;
    final left = current.selectedLeft;
    final right = current.selectedRight;
    final round = current.round;
    if (left == null || right == null || round == null) return;

    final result = gradeTap(round, left: left, right: right);
    final cardId = result.cardId;
    if (result.correct) {
      final matchedLeft = {...current.matchedLeft, left};
      state = current.copyWith(
        status: matchedLeft.length == round.pairs.length
            ? RoundStatus.finished
            : RoundStatus.playing,
        selectedLeft: null,
        selectedRight: null,
        matchedLeft: matchedLeft,
        matchedRight: {...current.matchedRight, right},
        feedback: null,
      );
    } else {
      state = current.copyWith(
        selectedLeft: null,
        selectedRight: null,
        wrongLeft: left,
        wrongRight: right,
        feedback: result.feedback,
        missedCardIds: {...current.missedCardIds, ?cardId},
      );
    }
    if (cardId == null) return;
    await ref
        .read(progressProvider.notifier)
        .record(
          cardId,
          correct: result.correct,
          when: ref.read(clockProvider)(),
        );
  }
}

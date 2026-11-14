import 'package:freezed_annotation/freezed_annotation.dart';

import 'pair_round.dart';

part 'round_state.freezed.dart';

/// Where the round on screen is.
enum RoundStatus {
  /// The words are being drawn.
  loading,

  /// A round is on screen and has unmatched pairs.
  playing,

  /// The pool could not fill a round.
  notEnoughWords,

  /// Every pair of the round is matched.
  finished,
}

/// The state of the round on screen.
// The sets are replaced, never changed in place.
@Freezed(makeCollectionsUnmodifiable: false)
abstract class RoundState with _$RoundState {
  const factory RoundState({
    @Default(RoundStatus.loading) RoundStatus status,
    PairRound? round,

    /// The Portuguese word tapped and waiting for a right word.
    String? selectedLeft,

    /// The right word tapped and waiting for a Portuguese word.
    String? selectedRight,

    /// Portuguese words of the locked pairs.
    @Default(<String>{}) Set<String> matchedLeft,

    /// Right words of the locked pairs.
    @Default(<String>{}) Set<String> matchedRight,

    /// The Portuguese word of the last wrong pair, kept until the next tap.
    String? wrongLeft,

    /// The right word of the last wrong pair, kept until the next tap.
    String? wrongRight,

    /// What the last wrong tap says, null when there is nothing to say.
    String? feedback,

    /// Ids of the cards missed at least once in this round.
    @Default(<String>{}) Set<String> missedCardIds,
  }) = _RoundState;
}

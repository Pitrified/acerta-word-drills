import 'package:freezed_annotation/freezed_annotation.dart';

import 'lookalike.dart';
import 'pair_round.dart';

part 'round_summary.freezed.dart';

/// One pair of a finished round, with what the summary says about it.
@freezed
abstract class SummaryEntry with _$SummaryEntry {
  const factory SummaryEntry({
    required RoundPair pair,

    /// Whether the word was matched wrongly at least once in the round.
    required bool missed,

    /// Whether the learner removed the word from the drill.
    required bool hidden,
  }) = _SummaryEntry;
}

/// A false friend of one of the round's words, as the summary lists it.
@freezed
abstract class FalseFriendEntry with _$FalseFriendEntry {
  const factory FalseFriendEntry({
    required RoundPair pair,

    /// A full or partial look-alike of the pair's word, in either language.
    required Lookalike lookalike,

    /// Whether the round's decoy came from this look-alike.
    required bool onBoard,
  }) = _FalseFriendEntry;
}

/// The finished round, pair by pair.
// The list is built once and never changed.
@Freezed(makeCollectionsUnmodifiable: false)
abstract class RoundSummary with _$RoundSummary {
  const RoundSummary._();

  const factory RoundSummary({
    /// One entry per pair, in round order.
    required List<SummaryEntry> entries,

    /// The false friends of the round's words, in round order.
    @Default(<FalseFriendEntry>[]) List<FalseFriendEntry> falseFriends,
  }) = _RoundSummary;

  /// The pairs never missed.
  int get rightFirstTime => entries.where((e) => !e.missed).length;
}

import 'package:freezed_annotation/freezed_annotation.dart';

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

/// The finished round, pair by pair.
// The list is built once and never changed.
@Freezed(makeCollectionsUnmodifiable: false)
abstract class RoundSummary with _$RoundSummary {
  const RoundSummary._();

  const factory RoundSummary({
    /// One entry per pair, in round order.
    required List<SummaryEntry> entries,
  }) = _RoundSummary;

  /// The pairs never missed.
  int get rightFirstTime => entries.where((e) => !e.missed).length;
}

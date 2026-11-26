import 'package:freezed_annotation/freezed_annotation.dart';

import 'answer_language.dart';
import 'lookalike.dart';
import 'word_card.dart';

part 'pair_round.freezed.dart';

/// One Portuguese word and the word it is matched with.
@freezed
abstract class RoundPair with _$RoundPair {
  const RoundPair._();

  const factory RoundPair({
    required WordCard card,

    /// The translation shown in the right column.
    required String right,
  }) = _RoundPair;

  /// The Portuguese word, shown in the left column.
  String get left => card.text;
}

/// A false friend placed in the right column; it matches nothing.
@freezed
abstract class Decoy with _$Decoy {
  const Decoy._();

  const factory Decoy({
    /// The word shown in the right column.
    required String text,

    /// The Portuguese word it is a false friend of.
    required String left,

    /// The look-alike of [left] the decoy comes from.
    required Lookalike lookalike,
  }) = _Decoy;

  /// The explanation shown when the learner taps it for [left].
  String get note => lookalike.note;
}

/// A built round: pairs, decoys and the shuffled right column.
// The lists are built once and never changed.
@Freezed(makeCollectionsUnmodifiable: false)
abstract class PairRound with _$PairRound {
  const factory PairRound({
    required AnswerLanguage language,
    required List<RoundPair> pairs,
    required List<Decoy> decoys,

    /// The pairs' right words and the decoy texts, shuffled.
    required List<String> rightColumn,
  }) = _PairRound;
}

/// The grade of one tap.
@freezed
abstract class TapResult with _$TapResult {
  const factory TapResult({
    required bool correct,

    /// A message for a wrong tap, null when the tap was right.
    String? feedback,

    /// The id of the left word's card, null when the word is not in the round.
    String? cardId,
  }) = _TapResult;
}

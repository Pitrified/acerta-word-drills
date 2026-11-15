import 'package:freezed_annotation/freezed_annotation.dart';

import 'answer_language.dart';
import 'level.dart';

part 'word_report.freezed.dart';
part 'word_report.g.dart';

/// A pair the learner flagged as wrong, with what was on screen.
// The list is built once and never changed.
@Freezed(makeCollectionsUnmodifiable: false)
abstract class WordReport with _$WordReport {
  const factory WordReport({
    /// The card id, the key of the report.
    required String cardId,

    /// The Portuguese word.
    required String text,
    required String pos,
    required Level level,
    required String gloss,

    /// The answer language of the round the pair was shown in.
    required AnswerLanguage language,

    /// The right word shown in the round.
    required String right,

    /// Every translation of the card in [language].
    required List<String> translations,
    required DateTime reportedAt,
  }) = _WordReport;

  factory WordReport.fromJson(Map<String, dynamic> json) =>
      _$WordReportFromJson(json);
}

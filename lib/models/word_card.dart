import 'package:freezed_annotation/freezed_annotation.dart';

import 'answer_language.dart';
import 'level.dart';
import 'lookalike.dart';

part 'word_card.freezed.dart';
part 'word_card.g.dart';

/// One Portuguese word with its translations and look-alikes.
// Freezed 3.2.3 emits a `final` parameter modifier for wrapped lists that the
// Dart 3.13 parser rejects, so lists are left as parsed.
@Freezed(makeCollectionsUnmodifiable: false)
abstract class WordCard with _$WordCard {
  const WordCard._();

  const factory WordCard({
    /// Stable id of the word, the key of its progress.
    required String id,
    required String text,
    required String pos,
    required Level level,

    /// Frequency score, higher is more common.
    required double freq,
    required String gloss,
    @Default(<String>[]) List<String> en,
    @Default(<String>[]) List<String> it,
    @Default(<Lookalike>[]) List<Lookalike> lookalikes,

    /// The topics of the word, such as `medical`; empty for most words.
    @Default(<String>[]) List<String> topics,

    /// Whether the word looks like a word of its own meaning; set by the card
    /// repository on load, not read from the asset.
    // Freezed copies the annotation onto the generated field, where it applies.
    // ignore: invalid_annotation_target
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool isCognate,
  }) = _WordCard;

  factory WordCard.fromJson(Map<String, dynamic> json) =>
      _$WordCardFromJson(json);

  /// The translations in [language], most frequent first.
  List<String> translationsIn(AnswerLanguage language) =>
      language == AnswerLanguage.en ? en : it;
}

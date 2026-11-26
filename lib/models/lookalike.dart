import 'package:freezed_annotation/freezed_annotation.dart';

part 'lookalike.freezed.dart';
part 'lookalike.g.dart';

/// How a look-alike word relates to the Portuguese word.
enum LookalikeKind {
  /// Never means the same as the Portuguese word.
  @JsonValue('full')
  full,

  /// Shares an everyday meaning with the Portuguese word.
  @JsonValue('partial')
  partial,

  /// Descends from the same word and means the same.
  @JsonValue('cognate')
  cognate;

  /// The kind in words, as shown to the learner.
  String get label => switch (this) {
    LookalikeKind.full => 'false friend',
    LookalikeKind.partial => 'partial false friend',
    LookalikeKind.cognate => 'cognate',
  };
}

/// A word in another language that looks like the Portuguese one.
// As on WordCard, the collections are left as parsed (a Freezed 3.2.3 bug).
@Freezed(makeCollectionsUnmodifiable: false)
abstract class Lookalike with _$Lookalike {
  const Lookalike._();

  const factory Lookalike({
    /// Language code of the look-alike, such as `en`.
    required String language,
    required String text,
    required LookalikeKind kind,
    @Default('') String note,

    /// For a false friend, the words of what the look-alike mainly means in
    /// the learner's other known language, by language code, most frequent
    /// first: it *bravo* means `{"en": ["good"]}`. Empty for a cognate, and
    /// where that meaning has no word in the other language.
    @Default(<String, List<String>>{}) Map<String, List<String>> means,
  }) = _Lookalike;

  factory Lookalike.fromJson(Map<String, dynamic> json) =>
      _$LookalikeFromJson(json);

  /// The language of the look-alike in words; an unknown code is shown as is.
  String get languageLabel => switch (language) {
    'en' => 'English',
    'it' => 'Italian',
    _ => language,
  };

  /// Whether the word misleads: a false friend rather than a cognate.
  bool get isTrap => kind != LookalikeKind.cognate;
}

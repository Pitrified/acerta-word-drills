/// The language of the right-hand column of a round.
enum AnswerLanguage {
  en,
  it;

  /// The language code used as a key in the card asset.
  String get code => name;

  /// The language name shown to the learner.
  String get label => switch (this) {
    AnswerLanguage.en => 'English',
    AnswerLanguage.it => 'Italian',
  };
}

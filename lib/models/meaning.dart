import 'level.dart';

/// One word that expresses a meaning, with its level in that meaning.
class MeaningWord {
  const MeaningWord({required this.text, this.level});

  final String text;

  /// The level of the word in the meaning; null when the asset gives none.
  final Level? level;

  /// The word and its level, such as `vocação · B2`; the bare word with none.
  String get label => level == null ? text : '$text · ${level!.label}';
}

/// One meaning: its glosses and the words that express it, by language.
class Meaning {
  const Meaning({required this.gloss, required this.words, this.glossPt});

  /// The English gloss.
  final String gloss;

  /// The Portuguese gloss, when the corpus has one.
  final String? glossPt;

  /// The words by language code (`pt`, `en`, `it`), most frequent in this
  /// meaning first; a language with no word is absent.
  final Map<String, List<MeaningWord>> words;
}

/// A meaning of one card's word, with the level of that word in it.
typedef WordMeaning = ({Meaning meaning, Level level});

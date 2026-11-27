import '../../models/answer_language.dart';
import '../../models/lookalike.dart';
import '../../models/word_card.dart';

/// The lowest [similarity] at which two words look alike.
const lookAlikeCut = 0.7;

const _plainLetters = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n',
};

/// [word] in lower case with the accents of pt, en and it taken off.
String foldWord(String word) {
  final buffer = StringBuffer();
  for (final char in word.toLowerCase().split('')) {
    buffer.write(_plainLetters[char] ?? char);
  }
  return buffer.toString();
}

/// How alike [a] and [b] are, from 0 to 1, once folded.
///
/// Twice the length of their longest common subsequence over the sum of their
/// lengths: *dezembro* and *December* give 0.75, *não* and *not* 0.67.
double similarity(String a, String b) {
  final x = foldWord(a);
  final y = foldWord(b);
  if (x.isEmpty && y.isEmpty) return 1;
  var previous = List<int>.filled(y.length + 1, 0);
  for (var i = 0; i < x.length; i++) {
    final current = List<int>.filled(y.length + 1, 0);
    for (var j = 0; j < y.length; j++) {
      current[j + 1] = x[i] == y[j]
          ? previous[j] + 1
          : (previous[j + 1] > current[j] ? previous[j + 1] : current[j]);
    }
    previous = current;
  }
  return 2 * previous[y.length] / (x.length + y.length);
}

/// Whether [a] and [b] look alike: a [similarity] of at least [lookAlikeCut].
bool looksAlike(String a, String b) => similarity(a, b) >= lookAlikeCut;

/// Whether [card] is a cognate card: its word looks like a word of its own
/// meaning, English or Italian.
///
/// The learner knows both languages, so such a card is easy whatever the
/// answer language. The look-alikes of the card play no part: they may name a
/// word outside this meaning.
bool isCognateCard(WordCard card) =>
    [...card.en, ...card.it].any((word) => looksAlike(card.text, word));

/// The look-alikes of [card] of [kind] in [language].
///
/// A look-alike that is itself a word of the card's meaning is left out: the
/// *andar* card means "go", *andare*, so its partial false friend *andare* is
/// no trap on this card.
List<Lookalike> falseFriendsIn(
  WordCard card,
  AnswerLanguage language,
  LookalikeKind kind,
) {
  final found = [
    for (final lookalike in card.lookalikes)
      if (lookalike.kind == kind && lookalike.language == language.code)
        lookalike,
  ];
  // Most cards have no look-alike, so the own words are folded only when needed.
  if (found.isEmpty) return found;
  final own = {
    for (final word in [...card.en, ...card.it]) foldWord(word),
  };
  return [
    for (final lookalike in found)
      if (!own.contains(foldWord(lookalike.text))) lookalike,
  ];
}

/// Whether [card] has a full or partial false friend, English or Italian.
///
/// The learner passes through both languages, so a false friend in the one
/// not on the board misleads too: pt *bravo* is "angry", it *bravo* "good".
bool hasFalseFriend(WordCard card) => AnswerLanguage.values.any(
  (language) =>
      falseFriendsIn(card, language, LookalikeKind.full).isNotEmpty ||
      falseFriendsIn(card, language, LookalikeKind.partial).isNotEmpty,
);

/// Whether [card] has a partial false friend, English or Italian.
bool hasPartialFalseFriend(WordCard card) => AnswerLanguage.values.any(
  (language) =>
      falseFriendsIn(card, language, LookalikeKind.partial).isNotEmpty,
);

/// The word [lookalike], a false friend of [card], puts on the board in a
/// round answered in [language]; null when it puts none.
///
/// A full false friend in [language] shows its own text. A full or partial
/// one in the other language shows the first word of what it means in
/// [language] ([Lookalike.means]), it *bravo* giving *good* for pt *bravo*,
/// unless that word is a translation of the card: the trap then leads to a
/// right answer, and the words after it are near-synonyms of it, no trap.
///
/// A look-alike that [Lookalike.sharesMeaning] puts none, in either language:
/// the Portuguese word is also used for what it mainly means, so tapping it
/// would not be wrong (pt *tarde* is also "late", it *tardi*).
String? decoyWordOf(
  WordCard card,
  Lookalike lookalike,
  AnswerLanguage language,
) {
  if (lookalike.sharesMeaning) return null;
  if (lookalike.language == language.code) {
    return lookalike.kind == LookalikeKind.full ? lookalike.text : null;
  }
  final lead = lookalike.means[language.code]?.firstOrNull;
  if (lead == null) return null;
  final translations = {
    for (final word in card.translationsIn(language)) word.toLowerCase(),
  };
  return translations.contains(lead.toLowerCase()) ? null : lead;
}

/// A word a round can show as the decoy of a card, with its look-alike.
typedef DecoyCandidate = ({String text, Lookalike lookalike});

/// The decoys [card] can give in a round answered in [language], through
/// [decoyWordOf]: its full false friends in [language] first, then its full
/// and partial ones in the other language.
List<DecoyCandidate> decoyCandidates(WordCard card, AnswerLanguage language) {
  final other = AnswerLanguage.values.firstWhere((l) => l != language);
  final lookalikes = [
    ...falseFriendsIn(card, language, LookalikeKind.full),
    ...falseFriendsIn(card, other, LookalikeKind.full),
    ...falseFriendsIn(card, other, LookalikeKind.partial),
  ];
  return [
    for (final lookalike in lookalikes)
      if (decoyWordOf(card, lookalike, language) case final text?)
        (text: text, lookalike: lookalike),
  ];
}

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

/// Whether [card] has a full or partial false friend in [language].
bool hasFalseFriendIn(WordCard card, AnswerLanguage language) =>
    falseFriendsIn(card, language, LookalikeKind.full).isNotEmpty ||
    falseFriendsIn(card, language, LookalikeKind.partial).isNotEmpty;

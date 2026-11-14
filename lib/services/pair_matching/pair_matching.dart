import 'dart:math';

import '../../models/answer_language.dart';
import '../../models/lookalike.dart';
import '../../models/pair_round.dart';
import '../../models/word_card.dart';

/// Cards drawn beyond the round size, so a dropped card does not shrink it.
const pairSpares = 3;

/// The fewest pairs worth a round.
const minPairs = 2;

/// The most false-friend decoys a round holds.
const maxRoundDecoys = 1;

/// Builds a round from [cards], taken in order.
///
/// A card whose text is already a left word is skipped. A card's right word is
/// its first translation in [language] that no other pair uses (compared in
/// lower case); a card with none left is skipped. Building stops at
/// [numPairs] pairs. Up to [maxDecoys] false friends of the paired cards join
/// the right column. Returns null when fewer than [minPairs] pairs were built.
PairRound? buildRound(
  List<WordCard> cards, {
  required AnswerLanguage language,
  required int numPairs,
  required Random random,
  int maxDecoys = maxRoundDecoys,
}) {
  final pairs = <RoundPair>[];
  final lefts = <String>{};
  final used = <String>{};
  for (final card in cards) {
    if (pairs.length >= numPairs) break;
    if (lefts.contains(card.text)) continue;
    final right = card
        .translationsIn(language)
        .where((t) => !used.contains(t.toLowerCase()))
        .firstOrNull;
    if (right == null) continue;
    used.add(right.toLowerCase());
    lefts.add(card.text);
    pairs.add(RoundPair(card: card, right: right));
  }
  if (pairs.length < minPairs) return null;

  final decoys = _decoys(pairs, language, used, maxDecoys);
  final rightColumn = [
    for (final pair in pairs) pair.right,
    for (final decoy in decoys) decoy.text,
  ]..shuffle(random);
  return PairRound(
    language: language,
    pairs: pairs,
    decoys: decoys,
    rightColumn: rightColumn,
  );
}

List<Decoy> _decoys(
  List<RoundPair> pairs,
  AnswerLanguage language,
  Set<String> used,
  int maxDecoys,
) {
  final decoys = <Decoy>[];
  for (final pair in pairs) {
    if (decoys.length >= maxDecoys) break;
    final hint = pair.card.lookalikes
        .where(
          (l) =>
              l.kind == LookalikeKind.full &&
              l.language == language.code &&
              !used.contains(l.text.toLowerCase()),
        )
        .firstOrNull;
    if (hint == null) continue;
    used.add(hint.text.toLowerCase());
    decoys.add(Decoy(text: hint.text, left: pair.left, note: hint.note));
  }
  return decoys;
}

/// Grades one tap of [left] and [right].
///
/// The tap is correct when [right] is the pair's right word for [left]. A
/// wrong tap on a decoy of the same [left] returns its note as feedback.
TapResult gradeTap(
  PairRound round, {
  required String left,
  required String right,
}) {
  final pair = round.pairs.where((p) => p.left == left).firstOrNull;
  final correct = pair != null && pair.right == right;
  if (correct) return TapResult(correct: true, cardId: pair.card.id);
  final decoy = round.decoys.where((d) => d.text == right).firstOrNull;
  final feedback = decoy != null && decoy.left == left && decoy.note.isNotEmpty
      ? 'False friend! ${decoy.note}'
      : 'Wrong pair.';
  return TapResult(correct: false, feedback: feedback, cardId: pair?.card.id);
}

import 'dart:math';

import '../../models/answer_language.dart';
import '../../models/pair_round.dart';
import '../../models/word_card.dart';
import '../selection/lookalikes.dart';

/// Cards drawn beyond the round size, so a dropped card does not shrink it.
const pairSpares = 3;

/// The fewest pairs worth a round.
const minPairs = 2;

/// The most false-friend decoys a round holds.
const maxRoundDecoys = 1;

/// The fewest pairs a round needs to reserve a partial false friend as well
/// as a full one; a smaller round is mostly traps with both.
const partialSlotMinPairs = 5;

/// Builds a round from [cards], taken in order.
///
/// A card whose text is already a left word is skipped. A card's right word is
/// its first translation in [language] that no other pair uses (compared in
/// lower case); a card with none left is skipped. Building stops at
/// [numPairs] pairs. Up to [maxDecoys] false friends of the paired cards join
/// the right column. The pairs come back shuffled with [random], so a card
/// drawn first for its false friend has no fixed place on the board. Returns
/// null when fewer than [minPairs] pairs were built.
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

  final decoys = _decoys(pairs, language, used, maxDecoys, random);
  pairs.shuffle(random);
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

/// Up to [maxDecoys] decoys, from the first pairs with a [decoyCandidates]
/// word not already a right word or a decoy (in [used]); a pair with several
/// gives one of them at random.
List<Decoy> _decoys(
  List<RoundPair> pairs,
  AnswerLanguage language,
  Set<String> used,
  int maxDecoys,
  Random random,
) {
  final decoys = <Decoy>[];
  for (final pair in pairs) {
    if (decoys.length >= maxDecoys) break;
    final candidates = [
      for (final candidate in decoyCandidates(pair.card, language))
        if (!used.contains(candidate.text.toLowerCase())) candidate,
    ];
    if (candidates.isEmpty) continue;
    final pick = candidates.length == 1
        ? candidates.single
        : candidates[random.nextInt(candidates.length)];
    used.add(pick.text.toLowerCase());
    decoys.add(
      Decoy(text: pick.text, left: pair.left, lookalike: pick.lookalike),
    );
  }
  return decoys;
}

/// Grades one tap of [left] and [right].
///
/// The tap is correct when [right] is the pair's right word for [left]. A
/// wrong tap on a decoy of the same [left] returns its note as feedback; a
/// decoy from a false friend in the other language first names it, as
/// "Italian bravo means good.", note or not.
TapResult gradeTap(
  PairRound round, {
  required String left,
  required String right,
}) {
  final pair = round.pairs.where((p) => p.left == left).firstOrNull;
  final correct = pair != null && pair.right == right;
  if (correct) return TapResult(correct: true, cardId: pair.card.id);
  final decoy = round.decoys.where((d) => d.text == right).firstOrNull;
  final String feedback;
  if (decoy == null || decoy.left != left) {
    feedback = 'Wrong pair.';
  } else if (decoy.lookalike.language != round.language.code) {
    final lookalike = decoy.lookalike;
    final named =
        'False friend! ${lookalike.languageLabel} ${lookalike.text} means '
        '${decoy.text}.';
    feedback = decoy.note.isEmpty ? named : '$named ${decoy.note}';
  } else {
    feedback = decoy.note.isNotEmpty
        ? 'False friend! ${decoy.note}'
        : 'Wrong pair.';
  }
  return TapResult(correct: false, feedback: feedback, cardId: pair?.card.id);
}

import 'dart:math';

import '../../models/answer_language.dart';
import '../../models/level.dart';
import '../../models/lookalike.dart';
import '../../models/word_card.dart';
import '../../models/word_progress.dart';
import 'lookalikes.dart';

/// The numbers behind [computeWeight].
class SelectionWeights {
  const SelectionWeights({
    this.base = 1.0,
    this.errorBoost = 3.0,
    this.unseenMultiplier = 5.0,
    this.recencyHalfLife = const Duration(hours: 1),
    this.levelFactor = defaultLevelFactor,
    this.trapFactor = 1.3,
    this.cognateFactor = 0.1,
  });

  /// Easier words come up a little more often.
  static const defaultLevelFactor = <Level, double>{
    Level.a1: 1.3,
    Level.a2: 1.2,
    Level.b1: 1.1,
    Level.b2: 1.0,
    Level.c1: 0.9,
    Level.c2: 0.8,
  };

  /// Weight of a seen word with no errors, before the other factors.
  final double base;

  /// Added to the multiplier for each recorded error.
  final double errorBoost;

  /// Multiplier for a word that was never graded.
  final double unseenMultiplier;

  /// Time after which the recency damping has halved.
  final Duration recencyHalfLife;
  final Map<Level, double> levelFactor;

  /// Multiplier for a word with a false friend in the answer language.
  final double trapFactor;

  /// Multiplier for a cognate card ([WordCard.isCognate]) with no false
  /// friend in the answer language.
  final double cognateFactor;
}

/// The weight of [card] in the draw, answered in [language]; 0 when the word
/// is hidden.
double computeWeight(
  WordCard card,
  WordProgress? progress, {
  required AnswerLanguage language,
  required DateTime now,
  SelectionWeights weights = const SelectionWeights(),
}) {
  if (progress != null && progress.hidden) return 0;

  var weight = weights.base;
  if (progress == null || progress.seen == 0) {
    weight *= weights.unseenMultiplier;
  } else {
    weight *= 1 + weights.errorBoost * progress.errors;
  }
  weight *= weights.levelFactor[card.level] ?? 1.0;
  if (hasFalseFriendIn(card, language)) {
    weight *= weights.trapFactor;
  } else if (card.isCognate) {
    weight *= weights.cognateFactor;
  }
  final lastSeenAt = progress?.lastSeenAt;
  if (lastSeenAt != null) {
    // A last-seen time in the future (a clock set back) counts as just now.
    final elapsed = max(0, now.difference(lastSeenAt).inMicroseconds);
    weight *= 1 - pow(0.5, elapsed / weights.recencyHalfLife.inMicroseconds);
  }
  return max(0, weight);
}

/// Draws up to [n] distinct cards from [pool], weighted by [computeWeight].
///
/// Sampling is without replacement and the result is in draw order. A repeated
/// id is dropped and a card of weight 0 is never drawn.
List<WordCard> selectCards(
  Iterable<WordCard> pool,
  Map<String, WordProgress> progress,
  int n, {
  required AnswerLanguage language,
  required Random random,
  required DateTime now,
  SelectionWeights weights = const SelectionWeights(),
}) {
  final cards = <WordCard>[];
  final cardWeights = <double>[];
  final ids = <String>{};
  var total = 0.0;
  for (final card in pool) {
    if (!ids.add(card.id)) continue;
    final weight = computeWeight(
      card,
      progress[card.id],
      language: language,
      now: now,
      weights: weights,
    );
    if (weight <= 0) continue;
    cards.add(card);
    cardWeights.add(weight);
    total += weight;
  }

  final chosen = <WordCard>[];
  final count = min(n, cards.length);
  for (var draw = 0; draw < count; draw++) {
    final target = random.nextDouble() * total;
    var running = 0.0;
    var index = -1;
    var last = -1;
    for (var i = 0; i < cards.length; i++) {
      if (cardWeights[i] <= 0) continue;
      last = i;
      running += cardWeights[i];
      if (running > target) {
        index = i;
        break;
      }
    }
    // Rounding can leave the running sum short of the target.
    if (index < 0) index = last;
    chosen.add(cards[index]);
    total -= cardWeights[index];
    cardWeights[index] = 0;
  }
  return chosen;
}

/// Draws up to [n] distinct cards for a round answered in [language], with
/// false friends reserved first.
///
/// The first card is drawn from the cards with a full false friend in
/// [language], so the round can show its decoy; when [partialSlot] is set, the
/// second from the rest with a partial one. The others come from the rest of
/// [pool]. Each draw is a [selectCards] with the same weights; a reserved slot
/// with nothing to draw leaves its card to the last draw, so the count is the
/// one [selectCards] would give.
List<WordCard> drawRound(
  Iterable<WordCard> pool,
  Map<String, WordProgress> progress,
  int n, {
  required AnswerLanguage language,
  required bool partialSlot,
  required Random random,
  required DateTime now,
  SelectionWeights weights = const SelectionWeights(),
}) {
  final cards = pool.toList();
  final chosen = <WordCard>[];
  final taken = <String>{};
  List<WordCard> rest() => [
    for (final card in cards)
      if (!taken.contains(card.id)) card,
  ];
  void reserve(LookalikeKind kind) {
    if (chosen.length >= n) return;
    final slot = selectCards(
      [
        for (final card in rest())
          if (falseFriendsIn(card, language, kind).isNotEmpty) card,
      ],
      progress,
      1,
      language: language,
      random: random,
      now: now,
      weights: weights,
    );
    for (final card in slot) {
      chosen.add(card);
      taken.add(card.id);
    }
  }

  reserve(LookalikeKind.full);
  if (partialSlot) reserve(LookalikeKind.partial);
  chosen.addAll(
    selectCards(
      rest(),
      progress,
      n - chosen.length,
      language: language,
      random: random,
      now: now,
      weights: weights,
    ),
  );
  return chosen;
}

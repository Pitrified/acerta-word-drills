import 'dart:math';

import '../../models/level.dart';
import '../../models/word_card.dart';
import '../../models/word_progress.dart';

/// The numbers behind [computeWeight].
class SelectionWeights {
  const SelectionWeights({
    this.base = 1.0,
    this.errorBoost = 3.0,
    this.unseenMultiplier = 5.0,
    this.recencyHalfLife = const Duration(hours: 1),
    this.levelFactor = defaultLevelFactor,
    this.trapFactor = 1.3,
    this.cognateFactor = 0.7,
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

  /// Multiplier for a word with a false friend.
  final double trapFactor;

  /// Multiplier for a word with a cognate and no false friend.
  final double cognateFactor;
}

/// The weight of [card] in the draw; 0 when the word is hidden.
double computeWeight(
  WordCard card,
  WordProgress? progress, {
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
  if (card.isTrap) {
    weight *= weights.trapFactor;
  } else if (card.hasCognate) {
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

import 'dart:io';
import 'dart:math';

import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/lookalike.dart';
import 'package:acerta/models/word_card.dart';
import 'package:acerta/services/cards/card_repository.dart';
import 'package:acerta/services/pair_matching/pair_matching.dart';
import 'package:acerta/services/selection/lookalikes.dart';
import 'package:acerta/services/selection/selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Tests run from the repo root. The asset is regenerated when the corpus
  // changes, so nothing here hardcodes its size.
  final repository = CardRepository.parse(
    File(cardsAssetPath).readAsStringSync(),
  );
  final cards = repository.cards;

  test('the count matches the header', () {
    expect(cards.length, repository.meta.count);
  });

  test('the asset is the format this build reads', () {
    expect(repository.meta.format, supportedCardsFormat);
  });

  test('every topic is a lowercase name and medical is among them', () {
    for (final card in cards) {
      for (final topic in card.topics) {
        expect(topic, matches(RegExp(r'^[a-z][a-z_ ]*$')), reason: card.id);
      }
    }
    expect(repository.topicCounts['medical'], greaterThan(0));
  });

  test('ids are unique', () {
    expect(cards.map((c) => c.id).toSet().length, cards.length);
  });

  test('every card has text, gloss and an English translation', () {
    for (final card in cards) {
      expect(card.text, isNotEmpty, reason: card.id);
      expect(card.gloss, isNotEmpty, reason: card.id);
      expect(card.en, isNotEmpty, reason: card.id);
    }
  });

  test('cards are sorted by frequency, most frequent first', () {
    for (var i = 1; i < cards.length; i++) {
      expect(
        cards[i].freq,
        lessThanOrEqualTo(cards[i - 1].freq),
        reason: 'card ${cards[i].id}',
      );
    }
  });

  test('every full look-alike has a note', () {
    for (final card in cards) {
      for (final lookalike in card.lookalikes) {
        if (lookalike.kind == LookalikeKind.full) {
          expect(lookalike.note, isNotEmpty, reason: card.id);
        }
      }
    }
  });

  test('cognate cards: dezembro and andar are, about half of all are', () {
    WordCard byText(String text) => cards.firstWhere((c) => c.text == text);
    expect(byText('dezembro').isCognate, isTrue);
    expect(byText('andar').isCognate, isTrue);
    final share = cards.where((c) => c.isCognate).length / cards.length;
    // Loose bounds: a guard against matching all or nothing, not a pin.
    expect(share, inInclusiveRange(0.4, 0.7));
  });

  test('8-pair C2 rounds have a decoy and a partial false friend', () {
    // A round loses its decoy only when the decoy is already a right word.
    for (final language in AnswerLanguage.values) {
      final pool = repository.pool(
        maxLevel: Level.c2,
        language: language,
        offTopics: const {},
      );
      final random = Random(7);
      var noDecoy = 0;
      for (var i = 0; i < 1000; i++) {
        final drawn = drawRound(
          pool,
          const {},
          8 + pairSpares,
          language: language,
          partialSlot: true,
          random: random,
          now: DateTime.utc(2026),
        );
        final round = buildRound(
          drawn,
          language: language,
          numPairs: 8,
          random: random,
        )!;
        if (round.decoys.isEmpty) noDecoy++;
        expect(
          round.pairs.any(
            (p) => falseFriendsIn(
              p.card,
              language,
              LookalikeKind.partial,
            ).isNotEmpty,
          ),
          isTrue,
          reason: language.code,
        );
      }
      expect(noDecoy, lessThanOrEqualTo(10), reason: language.code);
    }
  });
}

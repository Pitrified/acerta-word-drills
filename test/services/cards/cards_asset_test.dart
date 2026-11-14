import 'dart:io';

import 'package:acerta/models/lookalike.dart';
import 'package:acerta/services/cards/card_repository.dart';
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
}

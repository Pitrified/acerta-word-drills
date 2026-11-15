import 'dart:convert';
import 'dart:io';

import 'package:acerta/models/level.dart';
import 'package:acerta/services/cards/card_repository.dart';
import 'package:acerta/services/meanings/meanings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Tests run from the repo root. The asset is regenerated when the corpus
  // changes, so nothing here hardcodes its size.
  final text = File(meaningsAssetPath).readAsStringSync();
  final watch = Stopwatch()..start();
  final repository = MeaningsRepository.parse(text);
  watch.stop();
  final root = jsonDecode(text) as Map<String, dynamic>;
  final cards = CardRepository.parse(File(cardsAssetPath).readAsStringSync())
      .cards;

  test('the asset is the format this build reads', () {
    final meta = root['meta'] as Map<String, dynamic>;
    expect(meta['format'], supportedMeaningsFormat);
    expect((root['meanings'] as List<dynamic>).length, meta['meanings']);
    // The parse time is a measurement worth seeing in the test output.
    // ignore: avoid_print
    print('parse of the real meanings file: ${watch.elapsedMilliseconds} ms');
  });

  test('every card has at least one meaning', () {
    for (final card in cards) {
      expect(repository.meaningsOf(card.id), isNotEmpty, reason: card.id);
    }
  });

  test('every index is in range', () {
    final count = (root['meanings'] as List<dynamic>).length;
    for (final MapEntry(:key, :value)
        in (root['cards'] as Map<String, dynamic>).entries) {
      for (final link in value as List<dynamic>) {
        final index = (link as List<dynamic>)[0] as int;
        expect(index, inInclusiveRange(0, count - 1), reason: key);
      }
    }
  });

  test('the first meaning of a card lists the word of the card', () {
    for (final card in cards) {
      final own = repository.meaningsOf(card.id).first;
      expect(
        own.meaning.words['pt']!.map((w) => w.text),
        contains(card.text),
        reason: card.id,
      );
      expect(own.level, card.level, reason: card.id);
    }
  });

  test('carreira has its occupation meaning first', () {
    final card = cards.firstWhere((c) => c.text == 'carreira');

    final first = repository.meaningsOf(card.id).first;

    expect(first.level, Level.b1);
    expect(
      first.meaning.words['pt']!.map((w) => w.text),
      containsAll(['profissão', 'ocupação', 'vocação']),
    );
    expect(first.meaning.words['en']!.map((w) => w.text), contains('calling'));
  });
}

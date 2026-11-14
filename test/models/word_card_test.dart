import 'dart:convert';

import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/lookalike.dart';
import 'package:acerta/models/word_card.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixture = '''
[
  {"id": "a1", "text": "não", "pos": "noun", "level": "A1", "freq": 6.759,
   "gloss": "negation", "en": ["not", "non"], "it": ["non", "no"],
   "lookalikes": [
     {"language": "en", "text": "non", "kind": "cognate", "note": ""}]},
  {"id": "b2", "text": "pretender", "pos": "verb", "level": "B2", "freq": 3,
   "gloss": "to intend", "en": ["intend"], "it": [],
   "lookalikes": [
     {"language": "en", "text": "pretend", "kind": "full",
      "note": "pt means to intend, en means to feign"}]},
  {"id": "c1", "text": "casa", "pos": "noun", "level": "A1", "freq": 5.1,
   "gloss": "house", "en": ["house"], "it": ["casa"], "lookalikes": []},
  {"id": "d1", "text": "sensível", "pos": "adjective", "level": "C1",
   "freq": 2.5, "gloss": "sensitive", "en": ["sensitive"], "it": ["sensibile"],
   "lookalikes": [
     {"language": "en", "text": "sensible", "kind": "partial", "note": "x"},
     {"language": "it", "text": "sensibile", "kind": "cognate", "note": ""}]}
]
''';

List<WordCard> _cards() => [
  for (final json in jsonDecode(_fixture) as List<dynamic>)
    WordCard.fromJson(json as Map<String, dynamic>),
];

void main() {
  test('parses the fields and the level', () {
    final card = _cards().first;
    expect(card.id, 'a1');
    expect(card.text, 'não');
    expect(card.level, Level.a1);
    expect(card.freq, 6.759);
    expect(card.en, ['not', 'non']);
    expect(card.lookalikes.single.kind, LookalikeKind.cognate);
  });

  test('an integer freq parses as a double', () {
    expect(_cards()[1].freq, 3.0);
  });

  test('a full look-alike keeps its note', () {
    final lookalike = _cards()[1].lookalikes.single;
    expect(lookalike.kind, LookalikeKind.full);
    expect(lookalike.note, contains('feign'));
  });

  test('translationsIn picks the language list', () {
    final card = _cards().first;
    expect(card.translationsIn(AnswerLanguage.en), ['not', 'non']);
    expect(card.translationsIn(AnswerLanguage.it), ['non', 'no']);
    expect(_cards()[1].translationsIn(AnswerLanguage.it), isEmpty);
  });

  test('isTrap and hasCognate', () {
    final cards = _cards();
    expect(cards[0].isTrap, isFalse);
    expect(cards[0].hasCognate, isTrue);
    expect(cards[1].isTrap, isTrue);
    expect(cards[1].hasCognate, isFalse);
    expect(cards[2].isTrap, isFalse);
    expect(cards[2].hasCognate, isFalse);
    expect(cards[3].isTrap, isTrue);
    expect(cards[3].hasCognate, isTrue);
  });

  test('level label and order', () {
    expect(Level.c2.label, 'C2');
    expect(Level.a2.index, lessThan(Level.b1.index));
    expect(AnswerLanguage.it.code, 'it');
    expect(AnswerLanguage.it.label, 'Italian');
  });

  test('round trips through toJson and fromJson', () {
    for (final card in _cards()) {
      final json = jsonDecode(jsonEncode(card.toJson()));
      expect(WordCard.fromJson(json as Map<String, dynamic>), card);
    }
  });
}

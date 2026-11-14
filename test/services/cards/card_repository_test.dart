import 'dart:convert';

import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/services/cards/card_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _card(
  String id,
  String level, {
  List<String> it = const ['x'],
}) => {
  'id': id,
  'text': 'w$id',
  'pos': 'noun',
  'level': level,
  'freq': 1,
  'gloss': 'g',
  'en': ['e'],
  'it': it,
  'lookalikes': <Object>[],
};

String _text({int format = 1}) => jsonEncode({
  'meta': {
    'format': format,
    'language': 'pt',
    'lang_tools': 'v1',
    'corpus_built_at': '2026-01-01T00:00:00+00:00',
    'count': 5,
  },
  'cards': [
    _card('1', 'A1'),
    _card('2', 'A2', it: []),
    _card('3', 'B1'),
    _card('4', 'B2'),
    _card('5', 'A1'),
  ],
});

void main() {
  test('parse reads the meta and the cards', () {
    final repository = CardRepository.parse(_text());
    expect(repository.meta.format, 1);
    expect(repository.meta.langTools, 'v1');
    expect(repository.meta.count, 5);
    expect(repository.cards.map((c) => c.id), ['1', '2', '3', '4', '5']);
  });

  test('pool keeps cards at or under the level, in asset order', () {
    final repository = CardRepository.parse(_text());
    final ids = repository
        .pool(maxLevel: Level.b1, language: AnswerLanguage.en)
        .map((c) => c.id);
    expect(ids, ['1', '2', '3', '5']);
  });

  test('pool drops cards with no translation in the language', () {
    final repository = CardRepository.parse(_text());
    final italian = repository
        .pool(maxLevel: Level.c2, language: AnswerLanguage.it)
        .map((c) => c.id);
    expect(italian, isNot(contains('2')));
    final english = repository
        .pool(maxLevel: Level.c2, language: AnswerLanguage.en)
        .map((c) => c.id);
    expect(english, contains('2'));
  });

  test('byId finds a card and misses an unknown id', () {
    final repository = CardRepository.parse(_text());
    expect(repository.byId('3')?.level, Level.b1);
    expect(repository.byId('nope'), isNull);
  });

  test('countAt counts one level', () {
    final repository = CardRepository.parse(_text());
    expect(repository.countAt(Level.a1), 2);
    expect(repository.countAt(Level.b2), 1);
    expect(repository.countAt(Level.c1), 0);
  });

  test('cards cannot be modified', () {
    final repository = CardRepository.parse(_text());
    expect(() => repository.cards.clear(), throwsUnsupportedError);
  });

  test('an unknown format is refused', () {
    expect(
      () => CardRepository.parse(_text(format: 2)),
      throwsA(
        isA<UnsupportedCardsFormatError>().having((e) => e.found, 'found', 2),
      ),
    );
  });
}

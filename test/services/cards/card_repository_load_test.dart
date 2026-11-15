import 'dart:convert';

import 'package:acerta/services/cards/card_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A bundle that serves one text for every key and records the keys asked.
class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.text);

  final String text;
  final keys = <String>[];

  @override
  Future<ByteData> load(String key) async {
    keys.add(key);
    return ByteData.sublistView(utf8.encode(text));
  }
}

void main() {
  test('load reads the asset path and parses it in an isolate', () async {
    final bundle = _TextBundle(
      jsonEncode({
        'meta': {
          'format': 2,
          'language': 'pt',
          'lang_tools': 'v1',
          'corpus_built_at': '2026-01-01T00:00:00+00:00',
          'count': 1,
        },
        'cards': [
          {
            'id': '1',
            'text': 'não',
            'pos': 'adverb',
            'level': 'A1',
            'freq': 6.5,
            'gloss': 'negation',
            'en': ['not'],
            'it': ['non'],
            'lookalikes': <Object>[],
          },
        ],
      }),
    );

    final repository = await CardRepository.load(bundle);

    expect(bundle.keys, [cardsAssetPath]);
    expect(repository.cards.single.text, 'não');
    expect(repository.byId('1')?.en, ['not']);
  });
}

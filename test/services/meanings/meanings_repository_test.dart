import 'dart:convert';

import 'package:acerta/models/level.dart';
import 'package:acerta/services/meanings/meanings_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

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

final _meanings = <Map<String, Object?>>[
  {
    'gloss': 'a quick run',
    'gloss_pt': 'corrida rápida',
    'pt': [
      ['carreira', 'B2'],
    ],
    'en': [
      ['sprint', 'C1'],
      ['dash', null],
    ],
  },
  {
    'gloss': 'an occupation',
    'pt': [
      ['carreira', 'B1'],
      ['profissão', 'B2'],
    ],
    'it': [
      ['vocazione', 'B2'],
    ],
  },
];

void main() {
  test('meaningsOf keeps the order of the card links', () {
    final repository = meaningsRepositoryOf(
      meanings: _meanings,
      cards: {
        'c': [
          [1, 'B1'],
          [0, 'B2'],
        ],
      },
    );

    final found = repository.meaningsOf('c');

    expect(found.map((m) => m.meaning.gloss), ['an occupation', 'a quick run']);
    expect(found.map((m) => m.level), [Level.b1, Level.b2]);
  });

  test('a meaning has its glosses, words and levels', () {
    final repository = meaningsRepositoryOf(
      meanings: _meanings,
      cards: {
        'c': [
          [0, 'B2'],
          [1, 'B1'],
        ],
      },
    );

    final quick = repository.meaningsOf('c')[0].meaning;
    expect(quick.glossPt, 'corrida rápida');
    expect(quick.words['en']!.map((w) => w.text), ['sprint', 'dash']);
    expect(quick.words['en']!.map((w) => w.level), [Level.c1, null]);
    expect(quick.words['en']!.map((w) => w.label), ['sprint · C1', 'dash']);
    expect(quick.words.containsKey('it'), false);

    final job = repository.meaningsOf('c')[1].meaning;
    expect(job.glossPt, isNull);
    expect(job.words['it']!.single.label, 'vocazione · B2');
  });

  test('an unknown card id has no meanings', () {
    final repository = meaningsRepositoryOf(meanings: _meanings, cards: {});

    expect(repository.meaningsOf('nope'), isEmpty);
  });

  test('a format this build does not read is refused', () {
    final text = meaningsText(
      meanings: [],
      cards: {},
      format: supportedMeaningsFormat + 1,
    );

    expect(
      () => MeaningsRepository.parse(text),
      throwsA(
        isA<UnsupportedMeaningsFormatError>().having(
          (e) => e.found,
          'found',
          supportedMeaningsFormat + 1,
        ),
      ),
    );
  });

  test('a level that is not a CEFR level is refused', () {
    final text = meaningsText(
      meanings: _meanings,
      cards: {
        'c': [
          [0, 'D9'],
        ],
      },
    );

    expect(
      () => MeaningsRepository.parse(text),
      throwsA(isA<UnknownMeaningLevelError>()),
    );
  });

  test('load reads the asset path and parses it in an isolate', () async {
    final bundle = _TextBundle(
      meaningsText(
        meanings: _meanings,
        cards: {
          'c': [
            [0, 'B2'],
          ],
        },
      ),
    );

    final repository = await MeaningsRepository.load(bundle);

    expect(bundle.keys, [meaningsAssetPath]);
    expect(repository.meaningsOf('c').single.meaning.gloss, 'a quick run');
  });
}

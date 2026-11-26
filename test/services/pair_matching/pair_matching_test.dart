import 'dart:math';

import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/lookalike.dart';
import 'package:acerta/models/pair_round.dart';
import 'package:acerta/models/word_card.dart';
import 'package:acerta/services/pair_matching/pair_matching.dart';
import 'package:flutter_test/flutter_test.dart';

WordCard _card(
  String text, {
  List<String> en = const [],
  List<String> it = const [],
  List<Lookalike> lookalikes = const [],
}) => WordCard(
  id: 'id-$text',
  text: text,
  pos: 'noun',
  level: Level.a1,
  freq: 1,
  gloss: text,
  en: en,
  it: it,
  lookalikes: lookalikes,
);

PairRound? _build(
  List<WordCard> cards, {
  AnswerLanguage language = AnswerLanguage.en,
  int numPairs = 5,
  int maxDecoys = maxRoundDecoys,
}) => buildRound(
  cards,
  language: language,
  numPairs: numPairs,
  random: Random(0),
  maxDecoys: maxDecoys,
);

Map<String, String> _pairs(PairRound round) => {
  for (final p in round.pairs) p.left: p.right,
};

Lookalike _full(String text, {String language = 'en', String note = ''}) =>
    Lookalike(
      language: language,
      text: text,
      kind: LookalikeKind.full,
      note: note,
    );

void main() {
  final amor = _card('amor', en: ['love']);
  final paz = _card('paz', en: ['peace']);

  group('buildRound', () {
    test('pairs each card with its translation', () {
      final round = _build([amor, paz])!;
      expect(_pairs(round), {'amor': 'love', 'paz': 'peace'});
      expect(round.pairs.map((p) => p.card), unorderedEquals([amor, paz]));
      expect(round.language, AnswerLanguage.en);
    });

    test('a shared translation takes the next one', () {
      final round = _build([
        _card('casa', en: ['house', 'home']),
        _card('lar', en: ['House', 'hearth']),
      ])!;
      expect(_pairs(round), {'casa': 'house', 'lar': 'hearth'});
    });

    test('a card with no unused translation is dropped', () {
      final round = _build([
        _card('casa', en: ['house']),
        _card('moradia', en: ['house']),
        paz,
        _card('luz', en: ['light']),
      ], numPairs: 2)!;
      expect(_pairs(round), {'casa': 'house', 'paz': 'peace'});
    });

    test('stops at numPairs', () {
      final round = _build([
        amor,
        paz,
        _card('luz', en: ['light']),
        _card('sol', en: ['sun']),
      ], numPairs: 3)!;
      expect(
        round.pairs.map((p) => p.left),
        unorderedEquals(['amor', 'paz', 'luz']),
      );
    });

    test('skips a card whose text is already a left word', () {
      final round = _build([
        amor,
        _card('amor', en: ['affection']),
        paz,
      ])!;
      expect(_pairs(round), {'amor': 'love', 'paz': 'peace'});
    });

    test('is null under minPairs', () {
      expect(_build([amor]), isNull);
      expect(_build([]), isNull);
      expect(_build([amor, _card('x', en: const [])]), isNull);
      expect(_build([amor, paz], numPairs: 1), isNull);
    });

    test('Italian uses the it translations', () {
      final round = _build([
        _card('amor', en: ['love'], it: ['amore']),
        _card('paz', en: ['peace'], it: ['pace']),
        _card('lar', en: ['hearth']),
      ], language: AnswerLanguage.it)!;
      expect(_pairs(round), {'amor': 'amore', 'paz': 'pace'});
      expect(round.language, AnswerLanguage.it);
    });

    group('decoys', () {
      WordCard trap({String note = 'pt "esquisito" means weird'}) => _card(
        'esquisito',
        en: ['weird'],
        it: ['strano'],
        lookalikes: [
          _full('exquisite', note: note),
          _full('squisito', language: 'it', note: 'it note'),
        ],
      );

      test('a false friend joins the right column', () {
        final round = _build([trap(), paz])!;
        expect(round.decoys, [
          Decoy(
            text: 'exquisite',
            left: 'esquisito',
            lookalike: _full('exquisite', note: 'pt "esquisito" means weird'),
          ),
        ]);
        expect(round.decoys.single.note, 'pt "esquisito" means weird');
        expect(round.rightColumn.toList()..sort(), [
          'exquisite',
          'peace',
          'weird',
        ]);
      });

      test('a partial false friend is no decoy', () {
        final forte = _card(
          'forte',
          en: ['strong'],
          lookalikes: const [
            Lookalike(
              language: 'en',
              text: 'fort',
              kind: LookalikeKind.partial,
            ),
          ],
        );
        final round = _build([forte, paz])!;
        expect(round.decoys, isEmpty);
        expect(round.rightColumn.toList()..sort(), ['peace', 'strong']);
      });

      test('a cognate is no decoy', () {
        final card = _card(
          'nação',
          en: ['nation'],
          lookalikes: const [
            Lookalike(
              language: 'en',
              text: 'nation',
              kind: LookalikeKind.cognate,
            ),
          ],
        );
        expect(_build([card, paz])!.decoys, isEmpty);
      });

      test('no decoy when maxDecoys is 0', () {
        final round = _build([trap(), paz], maxDecoys: 0)!;
        expect(round.decoys, isEmpty);
        expect(round.rightColumn.toList()..sort(), ['peace', 'weird']);
      });

      test('only maxDecoys decoys are added', () {
        final other = _card('puxar', en: ['pull'], lookalikes: [_full('push')]);
        final one = _build([trap(), other, paz])!;
        expect(one.decoys.map((d) => d.text), ['exquisite']);
        final two = _build([trap(), other, paz], maxDecoys: 2)!;
        expect(two.decoys.map((d) => d.text), ['exquisite', 'push']);
      });

      test('only look-alikes in the answer language are decoys', () {
        final english = _build([trap(), paz])!;
        expect(english.decoys.map((d) => d.text), ['exquisite']);
        final italian = _build([
          trap(),
          _card('paz', it: ['pace']),
        ], language: AnswerLanguage.it)!;
        expect(italian.decoys.map((d) => d.text), ['squisito']);
        // A card whose only full look-alike is English adds none to Italian.
        final onlyEnglish = _card(
          'a',
          it: ['b'],
          lookalikes: [_full('exquisite')],
        );
        final round = _build([
          onlyEnglish,
          _card('c', it: ['d']),
        ], language: AnswerLanguage.it)!;
        expect(round.decoys, isEmpty);
      });

      group('from a false friend in the other language', () {
        const bravoIt = Lookalike(
          language: 'it',
          text: 'bravo',
          kind: LookalikeKind.partial,
          note: 'it bravo is good, pt bravo is angry',
          means: {
            'en': ['good'],
          },
        );
        WordCard bravo({List<Lookalike> lookalikes = const [bravoIt]}) =>
            _card('bravo', en: ['angry'], lookalikes: lookalikes);

        test('gives its lead word, partial or full', () {
          final round = _build([bravo(), paz])!;
          expect(round.decoys, [
            const Decoy(text: 'good', left: 'bravo', lookalike: bravoIt),
          ]);
          expect(round.rightColumn, contains('good'));
        });

        test('a tap names the look-alike, then the note', () {
          final round = _build([bravo(), paz])!;
          expect(
            gradeTap(round, left: 'bravo', right: 'good').feedback,
            'False friend! Italian bravo means good. '
            'it bravo is good, pt bravo is angry',
          );
          const plain = Lookalike(
            language: 'it',
            text: 'bravo',
            kind: LookalikeKind.full,
            means: {
              'en': ['good'],
            },
          );
          final bare = _build([
            bravo(lookalikes: const [plain]),
            paz,
          ])!;
          expect(
            gradeTap(bare, left: 'bravo', right: 'good').feedback,
            'False friend! Italian bravo means good.',
          );
          expect(
            gradeTap(bare, left: 'paz', right: 'good').feedback,
            'Wrong pair.',
          );
        });

        test('a lead word already a right word of the round is skipped', () {
          final round = _build([
            bravo(),
            _card('bom', en: ['good']),
          ])!;
          expect(round.decoys, isEmpty);
        });

        test('a card with both kinds gives either, at random', () {
          final card = bravo(lookalikes: [bravoIt, _full('brave')]);
          final texts = {
            for (var seed = 0; seed < 30; seed++)
              buildRound(
                [card, paz],
                language: AnswerLanguage.en,
                numPairs: 2,
                random: Random(seed),
              )!.decoys.single.text,
          };
          expect(texts, {'good', 'brave'});
        });
      });

      test('a decoy equal to a right word in the round is skipped', () {
        final card = _card(
          'esquisito',
          en: ['weird'],
          lookalikes: [_full('Peace'), _full('exquisite')],
        );
        final round = _build([card, paz])!;
        expect(round.decoys.map((d) => d.text), ['exquisite']);
        final none = _build([
          _card('x', en: ['a'], lookalikes: [_full('PEACE')]),
          paz,
        ])!;
        expect(none.decoys, isEmpty);
      });

      test('the right column holds every word exactly once', () {
        final round = _build([
          trap(),
          paz,
          amor,
          _card('luz', en: ['light']),
        ])!;
        expect(round.rightColumn, hasLength(5));
        expect(round.rightColumn.toList()..sort(), [
          'exquisite',
          'light',
          'love',
          'peace',
          'weird',
        ]);
      });

      test('the pairs are shuffled, so the decoy card has no fixed place', () {
        // The first card is the one a round reserves for its decoy.
        final cards = [
          trap(),
          for (final w in 'abcdefg'.split('')) _card(w, en: ['t$w']),
        ];
        final firsts = <String>{};
        for (var seed = 0; seed < 20; seed++) {
          final round = buildRound(
            cards,
            language: AnswerLanguage.en,
            numPairs: 8,
            random: Random(seed),
          )!;
          expect(
            round.pairs.map((p) => p.left),
            unorderedEquals(cards.map((c) => c.text)),
          );
          expect(round.decoys.single.left, 'esquisito');
          firsts.add(round.pairs.first.left);
        }
        expect(firsts.length, greaterThan(1));
      });

      test('the right column is shuffled with the given random', () {
        final cards = [
          for (final w in 'abcdefgh'.split('')) _card(w, en: ['t$w']),
        ];
        List<String> column(int seed) => buildRound(
          cards,
          language: AnswerLanguage.en,
          numPairs: 8,
          random: Random(seed),
        )!.rightColumn;
        expect(column(1), column(1));
        expect(column(1), isNot(column(2)));
        expect(
          column(1),
          isNot(['ta', 'tb', 'tc', 'td', 'te', 'tf', 'tg', 'th']),
        );
      });
    });
  });

  group('gradeTap', () {
    PairRound round() => _build([
      _card(
        'esquisito',
        en: ['weird'],
        lookalikes: [_full('exquisite', note: 'pt "esquisito" means weird')],
      ),
      paz,
    ])!;

    test('a right pair is correct', () {
      final result = gradeTap(round(), left: 'paz', right: 'peace');
      expect(result.correct, isTrue);
      expect(result.feedback, isNull);
      expect(result.cardId, 'id-paz');
    });

    test('a wrong pair is wrong', () {
      final result = gradeTap(round(), left: 'paz', right: 'weird');
      expect(result.correct, isFalse);
      expect(result.feedback, 'Wrong pair.');
      expect(result.cardId, 'id-paz');
    });

    test('the decoy for its own left word gives the note', () {
      final result = gradeTap(round(), left: 'esquisito', right: 'exquisite');
      expect(result.correct, isFalse);
      expect(result.feedback, 'False friend! pt "esquisito" means weird');
    });

    test('the decoy for another left word gives Wrong pair.', () {
      final result = gradeTap(round(), left: 'paz', right: 'exquisite');
      expect(result.feedback, 'Wrong pair.');
    });

    test('a decoy with an empty note gives Wrong pair.', () {
      final plain = _build([
        _card('esquisito', en: ['weird'], lookalikes: [_full('exquisite')]),
        paz,
      ])!;
      final result = gradeTap(plain, left: 'esquisito', right: 'exquisite');
      expect(result.feedback, 'Wrong pair.');
    });

    test('a left word outside the round has no card id', () {
      final result = gradeTap(round(), left: 'luz', right: 'peace');
      expect(result.correct, isFalse);
      expect(result.cardId, isNull);
      expect(result.feedback, 'Wrong pair.');
    });
  });
}

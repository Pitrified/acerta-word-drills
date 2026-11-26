import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/lookalike.dart';
import 'package:acerta/models/word_card.dart';
import 'package:acerta/services/selection/lookalikes.dart';
import 'package:flutter_test/flutter_test.dart';

WordCard _card(
  String text, {
  List<String> en = const [],
  List<String> it = const [],
  List<Lookalike> lookalikes = const [],
}) => WordCard(
  id: text,
  text: text,
  pos: 'verb',
  level: Level.a1,
  freq: 1,
  gloss: text,
  en: en,
  it: it,
  lookalikes: lookalikes,
);

void main() {
  test('foldWord lowers the case and takes the accents off', () {
    expect(foldWord('Ação'), 'acao');
    expect(foldWord('SAÚDE'), 'saude');
    expect(foldWord('perché'), 'perche');
  });

  test('similarity on the examples of the drill doc', () {
    expect(similarity('dezembro', 'December'), closeTo(0.75, 0.005));
    expect(similarity('andar', 'andare'), closeTo(0.91, 0.005));
    expect(similarity('saúde', 'salute'), closeTo(0.73, 0.005));
    expect(similarity('não', 'not'), closeTo(0.67, 0.005));
    expect(similarity('nação', 'not'), closeTo(0.5, 0.005));
    expect(similarity('casa', 'casa'), 1);
    expect(similarity('', ''), 1);
    expect(similarity('casa', ''), 0);
  });

  test('looksAlike cuts at 0.7', () {
    expect(looksAlike('dezembro', 'December'), isTrue);
    expect(looksAlike('não', 'not'), isFalse);
  });

  group('isCognateCard', () {
    test('a word like one of its own words, in either language', () {
      expect(isCognateCard(_card('andar', en: ['go'], it: ['andare'])), isTrue);
      expect(isCognateCard(_card('carreira', en: ['career'])), isTrue);
    });

    test('a word like none of its own words', () {
      expect(
        isCognateCard(_card('andar', en: ['walk'], it: ['camminare'])),
        isFalse,
      );
    });

    test('a cognate edge outside the meaning does not count', () {
      final card = _card(
        'andar',
        en: ['walk'],
        it: ['camminare'],
        lookalikes: const [
          Lookalike(
            language: 'it',
            text: 'andare',
            kind: LookalikeKind.cognate,
          ),
        ],
      );
      expect(isCognateCard(card), isFalse);
    });

    test('a card with no it words', () {
      expect(isCognateCard(_card('dezembro', en: ['December'])), isTrue);
      expect(isCognateCard(_card('andar')), isFalse);
    });
  });

  group('falseFriendsIn', () {
    const full = Lookalike(
      language: 'en',
      text: 'pretend',
      kind: LookalikeKind.full,
    );
    const partialIt = Lookalike(
      language: 'it',
      text: 'pretendere',
      kind: LookalikeKind.partial,
    );
    final card = _card(
      'pretender',
      en: ['intend'],
      it: ['intendere'],
      lookalikes: const [full, partialIt],
    );

    test('by kind and language', () {
      expect(falseFriendsIn(card, AnswerLanguage.en, LookalikeKind.full), [
        full,
      ]);
      expect(
        falseFriendsIn(card, AnswerLanguage.en, LookalikeKind.partial),
        isEmpty,
      );
      expect(falseFriendsIn(card, AnswerLanguage.it, LookalikeKind.partial), [
        partialIt,
      ]);
      expect(hasFalseFriend(card), isTrue);
      expect(hasPartialFalseFriend(card), isTrue);
    });

    test('a false friend that is a word of the meaning is left out', () {
      final andar = _card(
        'andar',
        en: ['go'],
        it: ['Andare'],
        lookalikes: const [
          Lookalike(
            language: 'it',
            text: 'andare',
            kind: LookalikeKind.partial,
          ),
        ],
      );
      expect(
        falseFriendsIn(andar, AnswerLanguage.it, LookalikeKind.partial),
        isEmpty,
      );
      expect(hasFalseFriend(andar), isFalse);
      expect(hasPartialFalseFriend(andar), isFalse);
    });
  });

  group('decoy candidates', () {
    const bravoIt = Lookalike(
      language: 'it',
      text: 'bravo',
      kind: LookalikeKind.partial,
      note: 'it bravo is good',
      means: {
        'en': ['good', 'skilled'],
      },
    );
    const angryEn = Lookalike(
      language: 'en',
      text: 'brave',
      kind: LookalikeKind.full,
      means: {
        'it': ['coraggioso'],
      },
    );
    final bravo = _card(
      'bravo',
      en: ['angry'],
      it: ['arrabbiato'],
      lookalikes: const [bravoIt, angryEn],
    );

    test('a false friend in the other language gives its lead word', () {
      expect(decoyCandidates(bravo, AnswerLanguage.en), [
        (text: 'brave', lookalike: angryEn),
        (text: 'good', lookalike: bravoIt),
      ]);
      expect(decoyCandidates(bravo, AnswerLanguage.it), [
        (text: 'coraggioso', lookalike: angryEn),
      ]);
      expect(decoyWordOf(bravo, bravoIt, AnswerLanguage.en), 'good');
      // A partial false friend in the answer language puts nothing on the board.
      expect(decoyWordOf(bravo, bravoIt, AnswerLanguage.it), isNull);
    });

    test('a lead word that translates the card gives none, not the next', () {
      // pt largo is "wide, grande"; en large means grande, grosso.
      const large = Lookalike(
        language: 'en',
        text: 'large',
        kind: LookalikeKind.full,
        means: {
          'it': ['grande', 'grosso'],
        },
      );
      final largo = _card(
        'largo',
        en: ['wide'],
        it: ['Grande', 'largo'],
        lookalikes: const [large],
      );
      expect(decoyCandidates(largo, AnswerLanguage.it), isEmpty);
    });

    test('a false friend with no word in the answer language gives none', () {
      const exquisite = Lookalike(
        language: 'en',
        text: 'exquisite',
        kind: LookalikeKind.full,
      );
      final card = _card(
        'esquisito',
        en: ['weird'],
        it: ['strano'],
        lookalikes: const [exquisite],
      );
      expect(decoyCandidates(card, AnswerLanguage.it), isEmpty);
      expect(decoyCandidates(card, AnswerLanguage.en), [
        (text: 'exquisite', lookalike: exquisite),
      ]);
    });

    test('a cognate gives none, whatever it means', () {
      final card = _card(
        'nação',
        en: ['nation'],
        lookalikes: const [
          Lookalike(
            language: 'it',
            text: 'nazione',
            kind: LookalikeKind.cognate,
            means: {
              'en': ['country'],
            },
          ),
        ],
      );
      expect(decoyCandidates(card, AnswerLanguage.en), isEmpty);
    });
  });
}

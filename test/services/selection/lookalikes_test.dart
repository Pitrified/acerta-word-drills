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
      expect(hasFalseFriendIn(card, AnswerLanguage.en), isTrue);
      expect(hasFalseFriendIn(card, AnswerLanguage.it), isTrue);
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
      expect(hasFalseFriendIn(andar, AnswerLanguage.it), isFalse);
    });
  });
}

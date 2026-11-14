import 'dart:math';

import 'package:acerta/models/level.dart';
import 'package:acerta/models/lookalike.dart';
import 'package:acerta/models/word_card.dart';
import 'package:acerta/models/word_progress.dart';
import 'package:acerta/services/selection/selection.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 1, 1, 12);

WordCard _card(
  String id, {
  Level level = Level.b2,
  List<Lookalike> lookalikes = const [],
}) => WordCard(
  id: id,
  text: id,
  pos: 'noun',
  level: level,
  freq: 1,
  gloss: id,
  lookalikes: lookalikes,
);

const _trap = Lookalike(language: 'en', text: 'x', kind: LookalikeKind.full);
const _cognate = Lookalike(
  language: 'en',
  text: 'y',
  kind: LookalikeKind.cognate,
);

double _weight(WordCard card, [WordProgress? progress]) =>
    computeWeight(card, progress, now: _now);

void main() {
  group('computeWeight', () {
    test('hidden is 0', () {
      expect(_weight(_card('a'), const WordProgress(hidden: true)), 0);
      expect(_weight(_card('a'), const WordProgress(seen: 3, hidden: true)), 0);
    });

    test('unseen takes the multiplier, with or without a record', () {
      expect(_weight(_card('a')), closeTo(5.0, 1e-9));
      expect(_weight(_card('a'), const WordProgress()), closeTo(5.0, 1e-9));
    });

    test('seen without errors is the base', () {
      const progress = WordProgress(seen: 4, correct: 4);
      expect(_weight(_card('a'), progress), closeTo(1.0, 1e-9));
    });

    test('each error adds the boost', () {
      const progress = WordProgress(seen: 4, correct: 2, errors: 2);
      expect(_weight(_card('a'), progress), closeTo(7.0, 1e-9));
    });

    test('level factors', () {
      const expected = {
        Level.a1: 1.3,
        Level.a2: 1.2,
        Level.b1: 1.1,
        Level.b2: 1.0,
        Level.c1: 0.9,
        Level.c2: 0.8,
      };
      for (final entry in expected.entries) {
        expect(
          _weight(_card('a', level: entry.key)),
          closeTo(5.0 * entry.value, 1e-9),
          reason: entry.key.label,
        );
      }
      final weights = [
        for (final level in Level.values) _weight(_card('a', level: level)),
      ];
      expect(weights, [...weights]..sort((a, b) => b.compareTo(a)));
    });

    test('a trap is boosted, a cognate damped', () {
      expect(
        _weight(_card('a', lookalikes: [_trap])),
        closeTo(5.0 * 1.3, 1e-9),
      );
      expect(
        _weight(_card('a', lookalikes: [_cognate])),
        closeTo(5.0 * 0.7, 1e-9),
      );
    });

    test('a trap and a cognate take the trap factor only', () {
      expect(
        _weight(_card('a', lookalikes: [_cognate, _trap])),
        closeTo(5.0 * 1.3, 1e-9),
      );
    });

    test('recency: elapsed 0 gives 0', () {
      final progress = WordProgress(seen: 1, correct: 1, lastSeenAt: _now);
      expect(_weight(_card('a'), progress), closeTo(0, 1e-9));
    });

    test('recency: one half life gives half', () {
      final progress = WordProgress(
        seen: 1,
        correct: 1,
        lastSeenAt: _now.subtract(const Duration(hours: 1)),
      );
      expect(_weight(_card('a'), progress), closeTo(0.5, 1e-9));
    });

    test('recency: two half lives give three quarters', () {
      final progress = WordProgress(
        seen: 1,
        correct: 1,
        lastSeenAt: _now.subtract(const Duration(hours: 2)),
      );
      expect(_weight(_card('a'), progress), closeTo(0.75, 1e-9));
    });

    test('recency: a last seen time in the future counts as elapsed 0', () {
      final progress = WordProgress(
        seen: 1,
        correct: 1,
        lastSeenAt: _now.add(const Duration(hours: 5)),
      );
      expect(_weight(_card('a'), progress), closeTo(0, 1e-9));
    });

    test('custom weights apply', () {
      const weights = SelectionWeights(
        base: 2,
        unseenMultiplier: 10,
        recencyHalfLife: Duration(minutes: 30),
      );
      expect(
        computeWeight(_card('a'), null, now: _now, weights: weights),
        closeTo(20, 1e-9),
      );
    });
  });

  group('selectCards', () {
    final pool = [
      for (final id in ['a', 'b', 'c', 'd', 'e']) _card(id),
    ];

    List<WordCard> select(
      Iterable<WordCard> cards,
      int n, {
      Map<String, WordProgress> progress = const {},
      int seed = 0,
    }) => selectCards(cards, progress, n, random: Random(seed), now: _now);

    test('returns n distinct cards', () {
      final chosen = select(pool, 3);
      expect(chosen, hasLength(3));
      expect({for (final c in chosen) c.id}, hasLength(3));
    });

    test('drops a repeated id', () {
      final chosen = select([_card('a'), _card('a'), _card('b')], 5);
      expect([for (final c in chosen) c.id]..sort(), ['a', 'b']);
    });

    test('never returns a hidden or a just-seen word', () {
      final progress = {
        'a': const WordProgress(hidden: true),
        'b': WordProgress(seen: 1, correct: 1, lastSeenAt: _now),
      };
      for (var seed = 0; seed < 20; seed++) {
        final ids = [
          for (final c in select(pool, 5, progress: progress, seed: seed)) c.id,
        ];
        expect(ids, isNot(contains('a')));
        expect(ids, isNot(contains('b')));
        expect(ids, hasLength(3));
      }
    });

    test('returns fewer than n when the pool is short', () {
      expect(select(pool, 10), hasLength(5));
      expect(select(const [], 3), isEmpty);
      expect(select(pool, 0), isEmpty);
    });

    test('is deterministic for a seeded random', () {
      List<String> ids(int seed) => [
        for (final c in select(pool, 4, seed: seed)) c.id,
      ];
      expect(ids(7), ids(7));
    });

    test('a weight 5 card is picked more often than a weight 1 card', () {
      final cards = [_card('heavy'), _card('light')];
      final progress = {'light': const WordProgress(seen: 2, correct: 2)};
      final random = Random(1);
      var heavy = 0;
      var light = 0;
      for (var i = 0; i < 3000; i++) {
        final first = selectCards(
          cards,
          progress,
          1,
          random: random,
          now: _now,
        ).single.id;
        if (first == 'heavy') {
          heavy++;
        } else {
          light++;
        }
      }
      // Expected share of the heavy card is 5 / 6.
      expect(heavy / (heavy + light), closeTo(5 / 6, 0.04));
    });

    test('the last card is taken when the draw reaches the total', () {
      final chosen = selectCards(
        pool,
        const {},
        1,
        random: _MaxRandom(),
        now: _now,
      );
      expect(chosen.single.id, 'e');
    });
  });
}

/// A random source whose double is the largest below 1.
class _MaxRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 1 - 1e-16;

  @override
  int nextInt(int max) => max - 1;
}

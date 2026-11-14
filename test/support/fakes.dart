import 'dart:math';

import 'package:acerta/models/cards_meta.dart';
import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/lookalike.dart';
import 'package:acerta/models/pair_round.dart';
import 'package:acerta/models/word_card.dart';
import 'package:acerta/models/word_progress.dart';
import 'package:acerta/providers/cards_provider.dart';
import 'package:acerta/providers/clock_provider.dart';
import 'package:acerta/providers/progress_provider.dart';
import 'package:acerta/providers/settings_provider.dart';
import 'package:acerta/services/cards/card_repository.dart';
import 'package:acerta/services/progress/progress_repository.dart';
import 'package:acerta/services/settings/settings_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// The fixed time of the tests.
final fixedNow = DateTime.utc(2026, 1, 1, 10);

/// A progress store in memory.
class FakeProgressRepository implements ProgressRepository {
  /// A store that starts with the records in [initial].
  FakeProgressRepository([Map<String, WordProgress>? initial])
    : _all = {...?initial};

  final Map<String, WordProgress> _all;

  @override
  Map<String, WordProgress> get all => Map.unmodifiable(_all);

  @override
  WordProgress? of(String id) => _all[id];

  @override
  Future<void> record(
    String id, {
    required bool correct,
    required DateTime when,
  }) async {
    final current = _all[id] ?? const WordProgress();
    _all[id] = current.copyWith(
      seen: current.seen + 1,
      correct: current.correct + (correct ? 1 : 0),
      errors: current.errors + (correct ? 0 : 1),
      lastSeenAt: when,
    );
  }

  @override
  Future<void> setHidden(String id, {required bool hidden}) async {
    final current = _all[id] ?? const WordProgress();
    _all[id] = current.copyWith(hidden: hidden);
  }

  @override
  Future<void> resetCounts() async {
    _all.removeWhere((id, progress) => !progress.hidden);
    _all.updateAll((id, progress) => const WordProgress(hidden: true));
  }
}

/// A settings store in memory.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this._settings = const DrillSettings()]);

  DrillSettings _settings;

  @override
  DrillSettings read() => _settings;

  @override
  Future<void> write(DrillSettings settings) async => _settings = settings;
}

/// A card `w<index>`, translated `en<index>` and `it<index>`.
///
/// It is A1 and has one full false friend in English, `look<index>`, with a
/// note, unless [level], [en], [it] or [lookalikes] say otherwise.
WordCard fakeCard(
  int index, {
  Level level = Level.a1,
  List<String>? en,
  List<String>? it,
  List<Lookalike>? lookalikes,
}) => WordCard(
  id: 'id$index',
  text: 'w$index',
  pos: 'noun',
  level: level,
  freq: 1,
  gloss: 'gloss $index',
  en: en ?? ['en$index'],
  it: it ?? ['it$index'],
  lookalikes:
      lookalikes ??
      [
        Lookalike(
          language: 'en',
          text: 'look$index',
          kind: LookalikeKind.full,
          note: 'note $index',
        ),
      ],
);

/// A card repository holding [cards].
CardRepository cardRepositoryOf(List<WordCard> cards) => CardRepository(
  meta: const CardsMeta(
    format: 1,
    language: 'pt',
    langTools: 'test',
    corpusBuiltAt: '2026-01-01T00:00:00+00:00',
    count: 0,
  ),
  cards: cards,
);

/// A card repository of [count] [fakeCard]s.
CardRepository fakeCardRepository(int count) =>
    cardRepositoryOf([for (var i = 0; i < count; i++) fakeCard(i)]);

/// The provider overrides every test of the round uses.
///
/// Pass [cards], or [loadCards] to control how the words load.
List<Override> roundOverrides({
  required FakeProgressRepository progress,
  CardRepository? cards,

  /// Replaces [cards] to hold the loading or fail the loading of the words.
  Future<CardRepository> Function()? loadCards,
  FakeSettingsRepository? settings,

  /// Replaces the fixed clock, to let time pass between rounds.
  DateTime Function()? clock,
  int seed = 1,
}) => [
  cardRepositoryProvider.overrideWith(
    (ref) => loadCards == null ? Future.value(cards) : loadCards(),
  ),
  progressRepositoryProvider.overrideWithValue(progress),
  settingsRepositoryProvider.overrideWithValue(
    settings ?? FakeSettingsRepository(),
  ),
  clockProvider.overrideWithValue(clock ?? () => fixedNow),
  randomProvider.overrideWithValue(Random(seed)),
];

/// The right word of [round] that goes with the Portuguese word [left].
String rightOf(PairRound round, String left) =>
    round.pairs.firstWhere((p) => p.left == left).right;

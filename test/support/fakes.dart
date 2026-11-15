import 'dart:convert';
import 'dart:math';

import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/cards_meta.dart';
import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/lookalike.dart';
import 'package:acerta/models/pair_round.dart';
import 'package:acerta/models/word_card.dart';
import 'package:acerta/models/word_progress.dart';
import 'package:acerta/models/word_report.dart';
import 'package:acerta/providers/cards_provider.dart';
import 'package:acerta/providers/clock_provider.dart';
import 'package:acerta/providers/learn_provider.dart';
import 'package:acerta/providers/meanings_provider.dart';
import 'package:acerta/providers/progress_provider.dart';
import 'package:acerta/providers/reports_provider.dart';
import 'package:acerta/providers/settings_provider.dart';
import 'package:acerta/services/cards/card_repository.dart';
import 'package:acerta/services/learn/learn_repository.dart';
import 'package:acerta/services/meanings/meanings_repository.dart';
import 'package:acerta/services/progress/progress_repository.dart';
import 'package:acerta/services/reports/report_export.dart';
import 'package:acerta/services/reports/report_repository.dart';
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

/// A reports store in memory.
class FakeReportRepository implements ReportRepository {
  /// A store that starts with the reports in [initial].
  FakeReportRepository([Iterable<WordReport> initial = const []])
    : _all = {for (final r in initial) r.cardId: r};

  final Map<String, WordReport> _all;

  @override
  Map<String, WordReport> get all => Map.unmodifiable(_all);

  @override
  Future<void> add(WordReport report) async => _all[report.cardId] = report;

  @override
  Future<void> remove(String id) async => _all.remove(id);

  @override
  Future<void> clear() async => _all.clear();
}

/// A learn store in memory.
class FakeLearnRepository implements LearnRepository {
  /// A store that starts with the marks in [initial], by card id.
  FakeLearnRepository([Map<String, DateTime>? initial]) : _all = {...?initial};

  final Map<String, DateTime> _all;

  @override
  Map<String, DateTime> get all => Map.unmodifiable(_all);

  @override
  Future<void> add(String id, DateTime when) async => _all[id] = when;

  @override
  Future<void> remove(String id) async => _all.remove(id);
}

/// A file saver that records what it was asked to write.
class FakeFileSaver implements FileSaver {
  /// Whether the learner accepts the dialog; false stands for a cancel.
  bool accept = true;

  /// An error to throw instead of saving.
  Object? error;

  /// The file names and texts of every call, in order.
  final List<({String fileName, String text})> saved = [];

  @override
  Future<bool> saveText({
    required String fileName,
    required String text,
  }) async {
    if (error != null) throw error!;
    if (!accept) return false;
    saved.add((fileName: fileName, text: text));
    return true;
  }
}

/// A report of the card [index] of [fakeCard], in English.
WordReport fakeReport(int index, {DateTime? reportedAt}) => WordReport(
  cardId: 'id$index',
  text: 'w$index',
  pos: 'noun',
  level: Level.a1,
  gloss: 'gloss $index',
  language: AnswerLanguage.en,
  right: 'en$index',
  translations: ['en$index'],
  reportedAt: reportedAt ?? fixedNow,
);

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
/// note and no topic, unless [level], [en], [it], [lookalikes] or [topics]
/// say otherwise.
WordCard fakeCard(
  int index, {
  Level level = Level.a1,
  List<String>? en,
  List<String>? it,
  List<Lookalike>? lookalikes,
  List<String> topics = const [],
}) => WordCard(
  id: 'id$index',
  text: 'w$index',
  pos: 'noun',
  level: level,
  freq: 1,
  gloss: 'gloss $index',
  topics: topics,
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
    format: 2,
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

/// The text of a meanings asset in the layout of [supportedMeaningsFormat].
///
/// [meanings] are the entries of `meanings`, [cards] maps a card id to its
/// `[index, level]` links.
String meaningsText({
  required List<Map<String, Object?>> meanings,
  required Map<String, List<List<Object>>> cards,
  int format = supportedMeaningsFormat,
}) => jsonEncode({
  'meta': {'format': format, 'meanings': meanings.length},
  'meanings': meanings,
  'cards': cards,
});

/// A meanings repository over [meaningsText].
MeaningsRepository meaningsRepositoryOf({
  required List<Map<String, Object?>> meanings,
  required Map<String, List<List<Object>>> cards,
}) => MeaningsRepository.parse(meaningsText(meanings: meanings, cards: cards));

/// A meanings repository that knows no card.
MeaningsRepository emptyMeaningsRepository() =>
    meaningsRepositoryOf(meanings: [], cards: {});

/// The provider overrides every test of the round uses.
///
/// Pass [cards], or [loadCards] to control how the words load.
List<Override> roundOverrides({
  required FakeProgressRepository progress,
  FakeReportRepository? reports,
  FakeLearnRepository? learn,
  FakeFileSaver? saver,
  CardRepository? cards,

  /// The meanings the word page reads; none by default.
  MeaningsRepository? meanings,

  /// Replaces [meanings] to hold the loading or fail the loading of them.
  Future<MeaningsRepository> Function()? loadMeanings,

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
  meaningsRepositoryProvider.overrideWith(
    (ref) => loadMeanings == null
        ? Future.value(meanings ?? emptyMeaningsRepository())
        : loadMeanings(),
  ),
  progressRepositoryProvider.overrideWithValue(progress),
  reportRepositoryProvider.overrideWithValue(reports ?? FakeReportRepository()),
  learnRepositoryProvider.overrideWithValue(learn ?? FakeLearnRepository()),
  fileSaverProvider.overrideWithValue(saver ?? FakeFileSaver()),
  settingsRepositoryProvider.overrideWithValue(
    settings ?? FakeSettingsRepository(),
  ),
  clockProvider.overrideWithValue(clock ?? () => fixedNow),
  randomProvider.overrideWithValue(Random(seed)),
];

/// The right word of [round] that goes with the Portuguese word [left].
String rightOf(PairRound round, String left) =>
    round.pairs.firstWhere((p) => p.left == left).right;

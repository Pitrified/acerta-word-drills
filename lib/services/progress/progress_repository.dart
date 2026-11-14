import 'dart:convert';

import 'package:hive/hive.dart';

import '../../models/word_progress.dart';

/// The Hive box that holds the progress, one entry per word.
const progressBoxName = 'progress';

/// What the learner has done with each word, kept in a Hive box.
///
/// The key is the card id and the value is the [WordProgress] as JSON text.
/// The decoded map is held in memory and every change is written through.
class ProgressRepository {
  ProgressRepository(this._box)
    : _all = {
        for (final key in _box.keys.cast<String>())
          key: WordProgress.fromJson(
            jsonDecode(_box.get(key)!) as Map<String, dynamic>,
          ),
      };

  /// Opens the progress box; Hive must be initialised.
  static Future<ProgressRepository> open() async =>
      ProgressRepository(await Hive.openBox<String>(progressBoxName));

  final Box<String> _box;
  final Map<String, WordProgress> _all;

  /// Every word with a record, by card id.
  Map<String, WordProgress> get all => Map.unmodifiable(_all);

  /// The record of the word [id], null when it has none.
  WordProgress? of(String id) => _all[id];

  /// Counts one graded tap on the word [id].
  Future<void> record(
    String id, {
    required bool correct,
    required DateTime when,
  }) {
    final current = _all[id] ?? const WordProgress();
    return _save(
      id,
      current.copyWith(
        seen: current.seen + 1,
        correct: current.correct + (correct ? 1 : 0),
        errors: current.errors + (correct ? 0 : 1),
        lastSeenAt: when,
      ),
    );
  }

  /// Hides the word [id] from the drill, or brings it back.
  Future<void> setHidden(String id, {required bool hidden}) {
    final current = _all[id] ?? const WordProgress();
    return _save(id, current.copyWith(hidden: hidden));
  }

  /// Forgets the counts and the last seen time of every word.
  ///
  /// The hidden flags stay; a word that is not hidden loses its record.
  Future<void> resetCounts() async {
    for (final id in _all.keys.toList()) {
      if (_all[id]!.hidden) {
        await _save(id, const WordProgress(hidden: true));
      } else {
        _all.remove(id);
        await _box.delete(id);
      }
    }
  }

  Future<void> _save(String id, WordProgress value) {
    _all[id] = value;
    return _box.put(id, jsonEncode(value.toJson()));
  }
}

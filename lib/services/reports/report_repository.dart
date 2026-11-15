import 'dart:convert';

import 'package:hive/hive.dart';

import '../../models/word_report.dart';

/// The Hive box that holds the reports, one entry per word.
const reportsBoxName = 'reports';

/// The pairs the learner reported, kept in a Hive box.
///
/// The key is the card id and the value is the [WordReport] as JSON text.
/// The decoded map is held in memory and every change is written through.
class ReportRepository {
  ReportRepository(this._box)
    : _all = {
        for (final key in _box.keys.cast<String>())
          key: WordReport.fromJson(
            jsonDecode(_box.get(key)!) as Map<String, dynamic>,
          ),
      };

  /// Opens the reports box; Hive must be initialised.
  static Future<ReportRepository> open() async =>
      ReportRepository(await Hive.openBox<String>(reportsBoxName));

  final Box<String> _box;
  final Map<String, WordReport> _all;

  /// Every report, by card id.
  Map<String, WordReport> get all => Map.unmodifiable(_all);

  /// Adds [report], replacing the report of the same word.
  Future<void> add(WordReport report) {
    _all[report.cardId] = report;
    return _box.put(report.cardId, jsonEncode(report.toJson()));
  }

  /// Removes the report of the word [id]; nothing happens without one.
  Future<void> remove(String id) {
    _all.remove(id);
    return _box.delete(id);
  }

  /// Removes every report.
  Future<void> clear() async {
    _all.clear();
    await _box.clear();
  }
}

import 'package:hive/hive.dart';

/// The Hive box that holds the words to learn, one entry per word.
const learnBoxName = 'learn';

/// The words the learner marked to learn, kept in a Hive box.
///
/// The key is the card id and the value is the time of the mark as ISO 8601
/// UTC text.
/// The decoded map is held in memory and every change is written through.
class LearnRepository {
  LearnRepository(this._box)
    : _all = {
        for (final key in _box.keys.cast<String>())
          key: DateTime.parse(_box.get(key)!),
      };

  /// Opens the learn box; Hive must be initialised.
  static Future<LearnRepository> open() async =>
      LearnRepository(await Hive.openBox<String>(learnBoxName));

  final Box<String> _box;
  final Map<String, DateTime> _all;

  /// The time each word was marked, by card id.
  Map<String, DateTime> get all => Map.unmodifiable(_all);

  /// Marks the word [id] at [when], replacing an earlier mark.
  Future<void> add(String id, DateTime when) {
    _all[id] = when;
    return _box.put(id, when.toUtc().toIso8601String());
  }

  /// Removes the mark of the word [id]; nothing happens without one.
  Future<void> remove(String id) {
    _all.remove(id);
    return _box.delete(id);
  }
}

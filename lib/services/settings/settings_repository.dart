import 'dart:convert';

import 'package:hive/hive.dart';

import '../../models/drill_settings.dart';

/// The Hive box that holds the settings.
const settingsBoxName = 'settings';

const _drillKey = 'drill';

/// The learner's drill settings, kept in a Hive box under one key.
class SettingsRepository {
  SettingsRepository(this._box);

  /// Opens the settings box; Hive must be initialised.
  static Future<SettingsRepository> open() async =>
      SettingsRepository(await Hive.openBox<String>(settingsBoxName));

  final Box<String> _box;

  /// The stored settings, the defaults when none are stored.
  ///
  /// `pairsPerRound` is held within [minPairsPerRound] and [maxPairsPerRound].
  DrillSettings read() {
    final text = _box.get(_drillKey);
    final settings = text == null
        ? const DrillSettings()
        : DrillSettings.fromJson(jsonDecode(text) as Map<String, dynamic>);
    return settings.copyWith(
      pairsPerRound: settings.pairsPerRound.clamp(
        minPairsPerRound,
        maxPairsPerRound,
      ),
    );
  }

  Future<void> write(DrillSettings settings) =>
      _box.put(_drillKey, jsonEncode(settings.toJson()));
}

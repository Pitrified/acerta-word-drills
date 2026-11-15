import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';

import '../../models/level.dart';
import '../../models/meaning.dart';
import '../logging/app_logger.dart';

/// Where the meanings asset is bundled.
const meaningsAssetPath = 'assets/cards/pt_meanings.json';

/// The meanings layout this build reads.
const supportedMeaningsFormat = 1;

/// The meanings asset has a layout this build does not read.
class UnsupportedMeaningsFormatError extends Error {
  UnsupportedMeaningsFormatError(this.found);

  /// The `format` found in the asset header.
  final int found;

  @override
  String toString() =>
      'UnsupportedMeaningsFormatError: asset format $found, '
      'this build reads format $supportedMeaningsFormat';
}

/// The meanings asset names a level that is not a CEFR level.
class UnknownMeaningLevelError extends Error {
  UnknownMeaningLevelError(this.found);

  /// The level text found in the asset.
  final String found;

  @override
  String toString() => 'UnknownMeaningLevelError: level "$found"';
}

/// Every meaning of every card word, held in memory.
class MeaningsRepository {
  MeaningsRepository({
    required List<Meaning> meanings,
    required Map<String, List<(int, Level)>> byCard,
  }) : _meanings = List.unmodifiable(meanings),
       _byCard = Map.unmodifiable(byCard);

  /// Parses the asset text; synchronous and free of side effects.
  ///
  /// Throws [UnsupportedMeaningsFormatError] when the header names a layout
  /// other than [supportedMeaningsFormat].
  factory MeaningsRepository.parse(String jsonText) {
    final root = jsonDecode(jsonText) as Map<String, dynamic>;
    final meta = root['meta'] as Map<String, dynamic>;
    final format = meta['format'] as int;
    if (format != supportedMeaningsFormat) {
      throw UnsupportedMeaningsFormatError(format);
    }
    final meanings = [
      for (final raw in root['meanings'] as List<dynamic>)
        _parseMeaning(raw as Map<String, dynamic>),
    ];
    final byCard = <String, List<(int, Level)>>{};
    for (final entry in (root['cards'] as Map<String, dynamic>).entries) {
      byCard[entry.key] = [
        for (final link in entry.value as List<dynamic>)
          ((link as List<dynamic>)[0] as int, _parseLevel(link[1] as String)),
      ];
    }
    return MeaningsRepository(meanings: meanings, byCard: byCard);
  }

  /// Reads the bundled asset and parses it off the UI isolate.
  static Future<MeaningsRepository> load(AssetBundle bundle) async {
    final text = await bundle.loadString(meaningsAssetPath);
    final repository = await Isolate.run(() => MeaningsRepository.parse(text));
    AppLogger.instance.info(
      'Loaded ${repository._meanings.length} meanings '
      'for ${repository._byCard.length} cards',
    );
    return repository;
  }

  final List<Meaning> _meanings;
  final Map<String, List<(int, Level)>> _byCard;

  /// The meanings of the card [cardId], its own meaning first and the others
  /// most frequent first; empty for an id the asset does not know.
  List<WordMeaning> meaningsOf(String cardId) => [
    for (final (index, level) in _byCard[cardId] ?? const <(int, Level)>[])
      (meaning: _meanings[index], level: level),
  ];

  static Meaning _parseMeaning(Map<String, dynamic> raw) => Meaning(
    gloss: raw['gloss'] as String,
    glossPt: raw['gloss_pt'] as String?,
    words: {
      for (final language in const ['pt', 'en', 'it'])
        if (raw[language] != null)
          language: [
            for (final word in raw[language] as List<dynamic>)
              MeaningWord(
                text: (word as List<dynamic>)[0] as String,
                level: word[1] == null ? null : _parseLevel(word[1] as String),
              ),
          ],
    },
  );

  static Level _parseLevel(String text) => Level.values.firstWhere(
    (level) => level.label == text,
    orElse: () => throw UnknownMeaningLevelError(text),
  );
}

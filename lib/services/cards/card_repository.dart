import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';

import '../../models/answer_language.dart';
import '../../models/cards_meta.dart';
import '../../models/level.dart';
import '../../models/word_card.dart';
import '../logging/app_logger.dart';

/// Where the card asset is bundled.
const cardsAssetPath = 'assets/cards/pt_cards.json';

/// The asset layout this build reads.
const supportedCardsFormat = 1;

/// The card asset has a layout this build does not read.
class UnsupportedCardsFormatError extends Error {
  UnsupportedCardsFormatError(this.found);

  /// The `format` found in the asset header.
  final int found;

  @override
  String toString() =>
      'UnsupportedCardsFormatError: asset format $found, '
      'this build reads format $supportedCardsFormat';
}

/// The word cards, held in memory.
class CardRepository {
  CardRepository({required this.meta, required List<WordCard> cards})
    : cards = List.unmodifiable(cards);

  /// Parses the asset text; synchronous and free of side effects.
  ///
  /// Throws [UnsupportedCardsFormatError] when the header names a layout
  /// other than [supportedCardsFormat].
  factory CardRepository.parse(String jsonText) {
    final root = jsonDecode(jsonText) as Map<String, dynamic>;
    final meta = CardsMeta.fromJson(root['meta'] as Map<String, dynamic>);
    if (meta.format != supportedCardsFormat) {
      throw UnsupportedCardsFormatError(meta.format);
    }
    final cards = [
      for (final card in root['cards'] as List<dynamic>)
        WordCard.fromJson(card as Map<String, dynamic>),
    ];
    return CardRepository(meta: meta, cards: cards);
  }

  /// Reads the bundled asset and parses it off the UI isolate.
  static Future<CardRepository> load(AssetBundle bundle) async {
    final text = await bundle.loadString(cardsAssetPath);
    final repository = await Isolate.run(() => CardRepository.parse(text));
    AppLogger.instance.info('Loaded ${repository.cards.length} cards');
    return repository;
  }

  final CardsMeta meta;

  /// Every card, in asset order (most frequent first).
  final List<WordCard> cards;

  late final Map<String, WordCard> _byId = {
    for (final card in cards) card.id: card,
  };

  late final Map<Level, int> _countByLevel = () {
    final counts = <Level, int>{};
    for (final card in cards) {
      counts[card.level] = (counts[card.level] ?? 0) + 1;
    }
    return counts;
  }();

  /// The cards at or under [maxLevel] with a translation in [language].
  List<WordCard> pool({
    required Level maxLevel,
    required AnswerLanguage language,
  }) => [
    for (final card in cards)
      if (card.level.index <= maxLevel.index &&
          card.translationsIn(language).isNotEmpty)
        card,
  ];

  /// The number of cards [pool] returns.
  int poolSize({required Level maxLevel, required AnswerLanguage language}) =>
      pool(maxLevel: maxLevel, language: language).length;

  /// The card with [id], or null when there is none.
  WordCard? byId(String id) => _byId[id];

  /// The number of cards of exactly [level].
  int countAt(Level level) => _countByLevel[level] ?? 0;
}

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meaning.dart';
import '../services/meanings/meanings_repository.dart';

/// The meanings of every word, read from the bundled asset the first time a
/// word page asks for them and kept after that.
final meaningsRepositoryProvider = FutureProvider<MeaningsRepository>(
  (ref) => MeaningsRepository.load(rootBundle),
);

/// The meanings of the card with the given id, its own meaning first.
final wordMeaningsProvider =
    Provider.family<AsyncValue<List<WordMeaning>>, String>(
      (ref, cardId) => ref
          .watch(meaningsRepositoryProvider)
          .whenData((meanings) => meanings.meaningsOf(cardId)),
    );

/// Whether the word page of a card shows every other meaning.
final showAllMeaningsProvider = NotifierProvider.autoDispose
    .family<ShowAllMeanings, bool, String>(ShowAllMeanings.new);

/// Holds whether the other meanings of one word page are all shown.
class ShowAllMeanings extends Notifier<bool> {
  ShowAllMeanings(this.cardId);

  /// The card of the page.
  final String cardId;

  @override
  bool build() => false;

  /// Shows the meanings that were folded away.
  void show() => state = true;
}

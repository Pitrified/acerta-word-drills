import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/answer_language.dart';
import '../models/level.dart';
import '../models/level_progress.dart';
import '../models/word_card.dart';
import '../models/word_stat.dart';
import 'cards_provider.dart';
import 'progress_provider.dart';
import 'settings_provider.dart';

/// The most words the most missed list holds.
const mostMissedLimit = 10;

/// The number of words in the pool of each answer language at the level cap
/// of the settings.
final poolSizesProvider = Provider<AsyncValue<Map<AnswerLanguage, int>>>((ref) {
  final maxLevel = ref.watch(settingsProvider.select((s) => s.maxLevel));
  return ref
      .watch(cardRepositoryProvider)
      .whenData(
        (cards) => {
          for (final language in AnswerLanguage.values)
            language: cards.poolSize(maxLevel: maxLevel, language: language),
        },
      );
});

/// The words the learner hid, sorted by text.
///
/// An id that is not in the card set any more is skipped.
final hiddenWordsProvider = Provider<AsyncValue<List<WordCard>>>((ref) {
  final progress = ref.watch(progressProvider);
  return ref.watch(cardRepositoryProvider).whenData((cards) {
    final hidden = <WordCard>[];
    for (final entry in progress.entries) {
      if (!entry.value.hidden) continue;
      final card = cards.byId(entry.key);
      if (card != null) hidden.add(card);
    }
    return hidden..sort((a, b) => a.text.compareTo(b.text));
  });
});

/// How many words are hidden; 0 while the words load.
final hiddenCountProvider = Provider<int>(
  (ref) => ref.watch(hiddenWordsProvider).value?.length ?? 0,
);

/// For each level from A1 to C2, the words seen out of the words there are.
///
/// A word is seen when its progress record has `seen > 0`: a record that only
/// holds the hidden flag does not count.
final levelProgressProvider = Provider<AsyncValue<List<LevelProgress>>>((ref) {
  final progress = ref.watch(progressProvider);
  return ref.watch(cardRepositoryProvider).whenData((cards) {
    final seen = <Level, int>{};
    for (final entry in progress.entries) {
      if (entry.value.seen <= 0) continue;
      final card = cards.byId(entry.key);
      if (card != null) seen[card.level] = (seen[card.level] ?? 0) + 1;
    }
    return [
      for (final level in Level.values)
        LevelProgress(
          level: level,
          seen: seen[level] ?? 0,
          total: cards.countAt(level),
        ),
    ];
  });
});

/// The words with the most errors: at least one error, most errors first,
/// ties by text, at most [mostMissedLimit].
///
/// An id that is not in the card set any more is skipped.
final mostMissedProvider = Provider<AsyncValue<List<WordStat>>>((ref) {
  final progress = ref.watch(progressProvider);
  return ref.watch(cardRepositoryProvider).whenData((cards) {
    final missed = <WordStat>[];
    for (final entry in progress.entries) {
      if (entry.value.errors <= 0) continue;
      final card = cards.byId(entry.key);
      if (card != null) {
        missed.add(WordStat(card: card, progress: entry.value));
      }
    }
    missed.sort((a, b) {
      final byErrors = b.progress.errors.compareTo(a.progress.errors);
      return byErrors != 0 ? byErrors : a.card.text.compareTo(b.card.text);
    });
    return missed.take(mostMissedLimit).toList();
  });
});

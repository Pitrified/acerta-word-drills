import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/answer_language.dart';
import '../models/lookalike.dart';
import '../models/pair_round.dart';
import '../models/round_summary.dart';
import '../services/selection/lookalikes.dart';
import 'progress_provider.dart';
import 'round_provider.dart';

/// The round on screen as a summary, null while there is no round.
///
/// It follows the progress, so a word hidden from the summary shows as hidden.
final roundSummaryProvider = Provider<RoundSummary?>((ref) {
  final round = ref.watch(roundProvider.select((s) => s.round));
  if (round == null) return null;
  final missed = ref.watch(roundProvider.select((s) => s.missedCardIds));
  final progress = ref.watch(progressProvider);
  return RoundSummary(
    entries: [
      for (final pair in round.pairs)
        SummaryEntry(
          pair: pair,
          missed: missed.contains(pair.card.id),
          hidden: progress[pair.card.id]?.hidden ?? false,
        ),
    ],
    falseFriends: falseFriendEntries(round),
  );
});

/// The false friends of [round]'s words, for the summary.
///
/// Pair by pair in round order; within a pair the answer language first, then
/// the other, and full before partial in each. The own-word rule of
/// [falseFriendsIn] holds, so a look-alike that is a word of the card's own
/// meaning is not listed.
List<FalseFriendEntry> falseFriendEntries(PairRound round) {
  final languages = [
    round.language,
    ...AnswerLanguage.values.where((l) => l != round.language),
  ];
  return [
    for (final pair in round.pairs)
      for (final language in languages)
        for (final kind in [LookalikeKind.full, LookalikeKind.partial])
          for (final lookalike in falseFriendsIn(pair.card, language, kind))
            FalseFriendEntry(
              pair: pair,
              lookalike: lookalike,
              onBoard: round.decoys.any(
                (d) => d.left == pair.left && d.lookalike == lookalike,
              ),
            ),
  ];
}

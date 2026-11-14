import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/round_summary.dart';
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
  );
});

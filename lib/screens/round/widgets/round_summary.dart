import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app.dart';
import '../../../models/answer_language.dart';
import '../../../models/round_summary.dart';
import '../../../models/word_report.dart';
import '../../../providers/clock_provider.dart';
import '../../../providers/learn_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../providers/reports_provider.dart';
import '../../../providers/round_provider.dart';
import '../../../providers/round_summary_provider.dart';

/// A finished round, pair by pair, with Next round and Home always in reach.
class RoundSummaryView extends ConsumerWidget {
  const RoundSummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(roundSummaryProvider);
    if (summary == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          // At most 8 entries, so they are all built and none is lazy.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Round done', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '${summary.rightFirstTime} of ${summary.entries.length} '
                  'right first time',
                  key: const Key('summary-score'),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                if (summary.falseFriends.isNotEmpty)
                  _FalseFriendsSection(entries: summary.falseFriends),
                for (final entry in summary.entries) _EntryCard(entry: entry),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const Key('next-round'),
                    onPressed: () =>
                        unawaited(ref.read(roundProvider.notifier).start()),
                    child: const Text('Next round'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('round-home'),
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The round's false friends, one row each, before the pair cards.
class _FalseFriendsSection extends ConsumerWidget {
  const _FalseFriendsSection({required this.entries});

  final List<FalseFriendEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final language = ref.read(roundProvider).round!.language;
    return Card(
      key: const Key('summary-false-friends'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('False friends', style: theme.textTheme.titleMedium),
            ),
            for (final entry in entries)
              _FalseFriendRow(entry: entry, language: language),
          ],
        ),
      ),
    );
  }
}

class _FalseFriendRow extends StatelessWidget {
  const _FalseFriendRow({required this.entry, required this.language});

  final FalseFriendEntry entry;

  /// The answer language of the round; a look-alike in another one names it.
  final AnswerLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = entry.pair.card;
    final lookalike = entry.lookalike;
    final word = lookalike.language == language.code
        ? lookalike.text
        : '${lookalike.languageLabel} ${lookalike.text}';
    final kind = [
      lookalike.kind.label,
      if (entry.onBoard) 'on the board',
    ].join(' · ');
    return InkWell(
      key: Key(
        'false-friend-${card.id}-${lookalike.language}-${lookalike.text}',
      ),
      onTap: () => unawaited(context.push(AppRoutes.word(card.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${card.text} - ${entry.pair.right}, not $word',
              style: theme.textTheme.bodyLarge,
            ),
            Text(kind, style: theme.textTheme.labelMedium),
            if (lookalike.note.isNotEmpty)
              Text(lookalike.note, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.entry});

  final SummaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final card = entry.pair.card;
    final reported = ref.watch(
      reportsProvider.select((r) => r.containsKey(card.id)),
    );
    final marked = ref.watch(
      learnProvider.select((l) => l.containsKey(card.id)),
    );
    final language = ref.read(roundProvider).round!.language;
    final otherLanguage = AnswerLanguage.values.firstWhere(
      (l) => l != language,
    );
    final other = card.translationsIn(otherLanguage);
    final title = [
      card.text,
      entry.pair.right,
      if (other.isNotEmpty) other.first,
    ].join(' - ');
    return Card(
      key: Key('summary-${card.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: Key('summary-open-${card.id}'),
              onTap: () => unawaited(context.push(AppRoutes.word(card.id))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          key: Key('summary-title-${card.id}'),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (entry.missed)
                        Container(
                          key: Key('missed-${card.id}'),
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'missed',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onErrorContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '${card.level.label} · ${card.pos}',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(card.gloss),
                  for (final lookalike in card.lookalikes)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${lookalike.languageLabel}: ${lookalike.text} '
                        '(${lookalike.kind.label})'
                        '${lookalike.note.isEmpty ? '' : ' - ${lookalike.note}'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    key: Key('report-${card.id}'),
                    onPressed: () => unawaited(
                      reported
                          ? ref.read(reportsProvider.notifier).undo(card.id)
                          : ref
                                .read(reportsProvider.notifier)
                                .add(
                                  WordReport(
                                    cardId: card.id,
                                    text: card.text,
                                    pos: card.pos,
                                    level: card.level,
                                    gloss: card.gloss,
                                    language: language,
                                    right: entry.pair.right,
                                    translations: card.translationsIn(language),
                                    reportedAt: ref
                                        .read(clockProvider)()
                                        .toUtc(),
                                  ),
                                ),
                    ),
                    child: Text(reported ? 'Reported, undo' : 'Report pair'),
                  ),
                  TextButton(
                    key: Key('hide-${card.id}'),
                    onPressed: () => unawaited(
                      ref
                          .read(progressProvider.notifier)
                          .setHidden(card.id, hidden: !entry.hidden),
                    ),
                    child: Text(
                      entry.hidden ? 'Hidden, undo' : "Don't show again",
                    ),
                  ),
                  TextButton(
                    key: Key('learn-${card.id}'),
                    onPressed: () => unawaited(
                      marked
                          ? ref.read(learnProvider.notifier).remove(card.id)
                          : ref.read(learnProvider.notifier).add(card.id),
                    ),
                    child: Text(marked ? 'To learn, undo' : 'Learn this'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

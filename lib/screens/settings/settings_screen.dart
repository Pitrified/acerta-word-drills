import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/answer_language.dart';
import '../../models/drill_settings.dart';
import '../../models/level.dart';
import '../../providers/learn_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/words_provider.dart';
import '../../utils/format_count.dart';

/// The drill settings; each change is written at once.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final pool = ref.watch(poolSizesProvider).value?[settings.answerLanguage];
    final topics = ref.watch(topicCountsProvider).value ?? const {};
    final hidden = ref.watch(hiddenCountProvider);
    final reports = ref.watch(reportsProvider).length;
    final learn = ref.watch(learnProvider).length;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level cap', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              key: const Key('settings-level'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in Level.values)
                  ChoiceChip(
                    key: Key('level-${level.label}'),
                    label: Text(level.label),
                    selected: settings.maxLevel == level,
                    onSelected: (_) => unawaited(notifier.setMaxLevel(level)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Pairs per round', style: theme.textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    key: const Key('settings-pairs'),
                    value: settings.pairsPerRound.toDouble(),
                    min: minPairsPerRound.toDouble(),
                    max: maxPairsPerRound.toDouble(),
                    divisions: maxPairsPerRound - minPairsPerRound,
                    label: '${settings.pairsPerRound}',
                    onChanged: (value) =>
                        unawaited(notifier.setPairsPerRound(value.round())),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${settings.pairsPerRound}',
                    key: const Key('settings-pairs-value'),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Answer language', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final language in AnswerLanguage.values)
                  ChoiceChip(
                    key: Key('language-${language.code}'),
                    label: Text(language.label),
                    selected: settings.answerLanguage == language,
                    onSelected: (_) =>
                        unawaited(notifier.setAnswerLanguage(language)),
                  ),
              ],
            ),
            if (pool != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${formatWords(pool)} up to ${settings.maxLevel.label} '
                  'have an ${settings.answerLanguage.label} translation.',
                  key: const Key('settings-language-count'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 24),
            Text('Topics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in topics.entries)
                  FilterChip(
                    key: Key('topic-${entry.key}'),
                    label: Text(
                      '${_capitalized(entry.key)} ${formatCount(entry.value)}',
                    ),
                    selected: !settings.offTopics.contains(entry.key),
                    onSelected: (on) =>
                        unawaited(notifier.setTopicOn(entry.key, on)),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Words with no topic are always included.',
                key: const Key('settings-topics-note'),
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              key: const Key('settings-hidden'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Hidden words'),
              trailing: Text('$hidden'),
              onTap: () => unawaited(context.push(AppRoutes.hiddenWords)),
            ),
            ListTile(
              key: const Key('settings-reports'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Reported pairs'),
              trailing: Text('$reports'),
              onTap: () => unawaited(context.push(AppRoutes.reports)),
            ),
            ListTile(
              key: const Key('settings-learn'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Words to learn'),
              trailing: Text('$learn'),
              onTap: () => unawaited(context.push(AppRoutes.learn)),
            ),
            ListTile(
              key: const Key('settings-reset'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Reset progress'),
              onTap: () => unawaited(_confirmReset(context, ref)),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalized(String topic) =>
      topic.isEmpty ? topic : topic[0].toUpperCase() + topic.substring(1);

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'The counts of every word are forgotten. '
          'Hidden words stay hidden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('reset-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(progressProvider.notifier).resetCounts();
    messenger.showSnackBar(const SnackBar(content: Text('Progress reset')));
  }
}

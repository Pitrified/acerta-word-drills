import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_report.dart';
import '../../providers/reports_provider.dart';

/// The reported pairs, with Remove on each, Save to file and Clear all.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider).values.toList()
      ..sort((a, b) => a.reportedAt.compareTo(b.reportedAt));
    final empty = reports.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Reported pairs')),
      body: Column(
        children: [
          Expanded(
            child: empty
                ? const Center(child: Text('No reported pairs.'))
                : ListView(
                    children: [
                      for (final report in reports) _ReportRow(report: report),
                    ],
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
                      key: const Key('reports-save'),
                      onPressed: empty
                          ? null
                          : () => unawaited(_save(context, ref)),
                      child: const Text('Save to file'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('reports-clear'),
                      onPressed: empty
                          ? null
                          : () => unawaited(_confirmClear(context, ref)),
                      child: const Text('Clear all'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await ref.read(reportsProvider.notifier).saveToFile();
      if (saved == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Saved $saved ${saved == 1 ? 'report' : 'reports'}'),
        ),
      );
    } on PlatformException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the file')),
      );
    }
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all reported pairs?'),
        content: const Text('The reports are deleted. The words stay hidden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('reports-clear-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(reportsProvider.notifier).clear();
  }
}

class _ReportRow extends ConsumerWidget {
  const _ReportRow({required this.report});

  final WordReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = report.reportedAt.toLocal().toIso8601String().substring(0, 10);
    return ListTile(
      key: Key('report-row-${report.cardId}'),
      title: Text('${report.text} - ${report.right}'),
      subtitle: Text('${report.language.label} · $date'),
      trailing: TextButton(
        key: Key('report-remove-${report.cardId}'),
        onPressed: () =>
            unawaited(ref.read(reportsProvider.notifier).remove(report.cardId)),
        child: const Text('Remove'),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../build_info.dart';
import '../models/word_report.dart';
import '../services/reports/report_export.dart';
import '../services/reports/report_repository.dart';
import 'clock_provider.dart';
import 'progress_provider.dart';
import 'provider_not_overridden_error.dart';

/// The reports store; `main` overrides it with the opened box.
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => throw ProviderNotOverriddenError('reportRepositoryProvider'),
);

/// Writes the reports file; tests replace it with a fake.
final fileSaverProvider = Provider<FileSaver>(
  (ref) => const ChannelFileSaver(),
);

/// The reported pairs, by card id.
final reportsProvider =
    NotifierProvider<ReportsNotifier, Map<String, WordReport>>(
      ReportsNotifier.new,
    );

/// Writes reports through the repository and refreshes the state.
class ReportsNotifier extends Notifier<Map<String, WordReport>> {
  ReportRepository get _repository => ref.read(reportRepositoryProvider);

  @override
  Map<String, WordReport> build() => ref.read(reportRepositoryProvider).all;

  /// Reports a pair and hides its word.
  Future<void> add(WordReport report) async {
    await _repository.add(report);
    state = _repository.all;
    await ref
        .read(progressProvider.notifier)
        .setHidden(report.cardId, hidden: true);
  }

  /// Takes the report back and shows the word again.
  Future<void> undo(String id) async {
    await _repository.remove(id);
    state = _repository.all;
    await ref.read(progressProvider.notifier).setHidden(id, hidden: false);
  }

  /// Removes the report; the word stays hidden.
  Future<void> remove(String id) async {
    await _repository.remove(id);
    state = _repository.all;
  }

  /// Removes every report.
  Future<void> clear() async {
    await _repository.clear();
    state = _repository.all;
  }

  /// Asks the learner where to save every report as a JSON lines file.
  ///
  /// Returns how many reports were written, null when the learner cancels.
  /// A failure of the save dialog throws a `PlatformException`.
  Future<int?> saveToFile() async {
    final reports = state.values.toList();
    final saved = await ref
        .read(fileSaverProvider)
        .saveText(
          fileName: ReportExport.fileName(ref.read(clockProvider)()),
          text: ReportExport.toJsonLines(reports, appVersion: appVersion),
        );
    return saved ? reports.length : null;
  }
}

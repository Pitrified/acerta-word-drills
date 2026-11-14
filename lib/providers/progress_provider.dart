import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word_progress.dart';
import '../services/progress/progress_repository.dart';
import 'provider_not_overridden_error.dart';

/// The progress store; `main` overrides it with the opened box.
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => throw ProviderNotOverriddenError('progressRepositoryProvider'),
);

/// The progress of every word with a record, by card id.
final progressProvider =
    NotifierProvider<ProgressNotifier, Map<String, WordProgress>>(
      ProgressNotifier.new,
    );

/// Writes progress through the repository and refreshes the state.
class ProgressNotifier extends Notifier<Map<String, WordProgress>> {
  ProgressRepository get _repository => ref.read(progressRepositoryProvider);

  @override
  Map<String, WordProgress> build() => ref.read(progressRepositoryProvider).all;

  Future<void> record(
    String id, {
    required bool correct,
    required DateTime when,
  }) async {
    await _repository.record(id, correct: correct, when: when);
    state = _repository.all;
  }

  Future<void> setHidden(String id, {required bool hidden}) async {
    await _repository.setHidden(id, hidden: hidden);
    state = _repository.all;
  }

  Future<void> resetCounts() async {
    await _repository.resetCounts();
    state = _repository.all;
  }
}

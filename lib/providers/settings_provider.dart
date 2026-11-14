import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/answer_language.dart';
import '../models/drill_settings.dart';
import '../models/level.dart';
import '../services/settings/settings_repository.dart';
import 'provider_not_overridden_error.dart';

/// The settings store; `main` overrides it with the opened box.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw ProviderNotOverriddenError('settingsRepositoryProvider'),
);

/// The learner's drill settings.
final settingsProvider = NotifierProvider<SettingsNotifier, DrillSettings>(
  SettingsNotifier.new,
);

/// Writes each change through the repository.
class SettingsNotifier extends Notifier<DrillSettings> {
  @override
  DrillSettings build() => ref.read(settingsRepositoryProvider).read();

  Future<void> setMaxLevel(Level level) =>
      _write(state.copyWith(maxLevel: level));

  Future<void> setPairsPerRound(int pairs) =>
      _write(state.copyWith(pairsPerRound: pairs));

  Future<void> setAnswerLanguage(AnswerLanguage language) =>
      _write(state.copyWith(answerLanguage: language));

  Future<void> _write(DrillSettings settings) async {
    await ref.read(settingsRepositoryProvider).write(settings);
    state = settings;
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'answer_language.dart';
import 'level.dart';

part 'drill_settings.freezed.dart';
part 'drill_settings.g.dart';

/// The fewest pairs a round can have.
const minPairsPerRound = 3;

/// The most pairs a round can have.
const maxPairsPerRound = 8;

/// The learner's choices for the drill.
@freezed
abstract class DrillSettings with _$DrillSettings {
  const factory DrillSettings({
    /// The hardest level a round draws from.
    @Default(Level.b1) Level maxLevel,
    @Default(5) int pairsPerRound,
    @Default(AnswerLanguage.en) AnswerLanguage answerLanguage,
  }) = _DrillSettings;

  factory DrillSettings.fromJson(Map<String, dynamic> json) =>
      _$DrillSettingsFromJson(json);
}

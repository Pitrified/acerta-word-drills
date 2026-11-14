import 'package:freezed_annotation/freezed_annotation.dart';

import 'word_card.dart';
import 'word_progress.dart';

part 'word_stat.freezed.dart';

/// A word of the card set with what the learner has done with it.
@freezed
abstract class WordStat with _$WordStat {
  const factory WordStat({
    required WordCard card,
    required WordProgress progress,
  }) = _WordStat;
}

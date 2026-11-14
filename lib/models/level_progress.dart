import 'package:freezed_annotation/freezed_annotation.dart';

import 'level.dart';

part 'level_progress.freezed.dart';

/// How many of the words of one level the learner has seen.
@freezed
abstract class LevelProgress with _$LevelProgress {
  const factory LevelProgress({
    required Level level,

    /// Words of exactly [level] with at least one graded tap.
    required int seen,

    /// Words of exactly [level] in the card set.
    required int total,
  }) = _LevelProgress;
}

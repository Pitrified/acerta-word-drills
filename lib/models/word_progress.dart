import 'package:freezed_annotation/freezed_annotation.dart';

part 'word_progress.freezed.dart';
part 'word_progress.g.dart';

/// What the learner has done with one word.
@freezed
abstract class WordProgress with _$WordProgress {
  const factory WordProgress({
    /// Graded taps on the word.
    @Default(0) int seen,

    /// Taps that matched the word with its translation.
    @Default(0) int correct,

    /// Taps that matched the word with anything else.
    @Default(0) int errors,
    DateTime? lastSeenAt,

    /// Whether the learner removed the word from the drill.
    @Default(false) bool hidden,
  }) = _WordProgress;

  factory WordProgress.fromJson(Map<String, dynamic> json) =>
      _$WordProgressFromJson(json);
}

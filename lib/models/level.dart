import 'package:json_annotation/json_annotation.dart';

/// CEFR level of a word, ordered from easiest to hardest.
///
/// Levels compare by `index`.
enum Level {
  @JsonValue('A1')
  a1,
  @JsonValue('A2')
  a2,
  @JsonValue('B1')
  b1,
  @JsonValue('B2')
  b2,
  @JsonValue('C1')
  c1,
  @JsonValue('C2')
  c2;

  /// The level as written in the asset and shown to the learner, such as `A1`.
  String get label => name.toUpperCase();
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cards_meta.freezed.dart';
part 'cards_meta.g.dart';

/// The header of the card asset.
@freezed
abstract class CardsMeta with _$CardsMeta {
  const factory CardsMeta({
    /// Version of the asset layout.
    required int format,
    required String language,

    /// The lang-tools version the asset was exported from.
    required String langTools,

    /// When the corpus was built, as written in the asset.
    required String corpusBuiltAt,
    required int count,
  }) = _CardsMeta;

  factory CardsMeta.fromJson(Map<String, dynamic> json) =>
      _$CardsMetaFromJson(json);
}

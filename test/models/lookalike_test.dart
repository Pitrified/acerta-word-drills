import 'package:acerta/models/lookalike.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each kind is named in words', () {
    expect(LookalikeKind.full.label, 'false friend');
    expect(LookalikeKind.partial.label, 'partial false friend');
    expect(LookalikeKind.cognate.label, 'cognate');
  });

  test('the language is named in words', () {
    const base = Lookalike(language: 'en', text: 'x', kind: LookalikeKind.full);
    expect(base.languageLabel, 'English');
    expect(base.copyWith(language: 'it').languageLabel, 'Italian');
    expect(base.copyWith(language: 'es').languageLabel, 'es');
  });

  test('means is read from the asset, and empty when absent', () {
    final bravo = Lookalike.fromJson({
      'language': 'it',
      'text': 'bravo',
      'kind': 'partial',
      'note': 'n',
      'means': {
        'en': ['good', 'skilled'],
      },
    });
    expect(bravo.means, {
      'en': ['good', 'skilled'],
    });
    final plain = Lookalike.fromJson({
      'language': 'en',
      'text': 'x',
      'kind': 'cognate',
    });
    expect(plain.means, isEmpty);
  });

  test('sharesMeaning is read from shares_meaning, and false when absent', () {
    final tardi = Lookalike.fromJson({
      'language': 'it',
      'text': 'tardi',
      'kind': 'partial',
      'shares_meaning': true,
    });
    expect(tardi.sharesMeaning, isTrue);
    final plain = Lookalike.fromJson({
      'language': 'it',
      'text': 'bravo',
      'kind': 'partial',
    });
    expect(plain.sharesMeaning, isFalse);
  });
}

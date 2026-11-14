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
}

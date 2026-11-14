import 'package:acerta/utils/format_count.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatCount puts a comma between thousands', () {
    expect(formatCount(0), '0');
    expect(formatCount(999), '999');
    expect(formatCount(1000), '1,000');
    expect(formatCount(1893), '1,893');
    expect(formatCount(29376), '29,376');
    expect(formatCount(1234567), '1,234,567');
    expect(formatCount(-1234), '-1,234');
  });

  test('formatWords uses the singular for one', () {
    expect(formatWords(1), '1 word');
    expect(formatWords(0), '0 words');
    expect(formatWords(1893), '1,893 words');
  });
}

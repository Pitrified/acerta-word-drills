import 'dart:io';

import 'package:acerta/data_credit.dart';
import 'package:flutter_test/flutter_test.dart';

/// The text of `DATA_LICENSE.md` after the heading line [heading].
List<String> _after(String heading) {
  final lines = File('DATA_LICENSE.md').readAsLinesSync();
  final start = lines.indexOf(heading);
  expect(start, isNot(-1), reason: 'DATA_LICENSE.md has no "$heading"');
  return lines.sublist(start + 1);
}

void main() {
  test('dataCredit is the block quote under Credit', () {
    final quote = _after('## Credit')
        .skipWhile((line) => !line.startsWith('>'))
        .takeWhile((line) => line.startsWith('>'))
        .map((line) => line.substring(2));
    expect(dataCredit, quote.join(' '));
  });

  test('wordNetLicense is the text block under the WordNet license', () {
    final block = _after('## WordNet 3.0 license')
        .skipWhile((line) => line != '```text')
        .skip(1)
        .takeWhile((line) => line != '```');
    expect(wordNetLicense, block.join('\n'));
  });
}

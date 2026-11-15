import 'dart:convert';

import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/models/word_report.dart';
import 'package:acerta/services/reports/report_export.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  group('toJsonLines', () {
    test('writes one object per line with every field', () {
      final report = WordReport(
        cardId: 'abc',
        text: 'voluto',
        pos: 'adj',
        level: Level.c1,
        gloss: 'a gloss',
        language: AnswerLanguage.it,
        right: 'voluto',
        translations: ['one', 'two'],
        reportedAt: DateTime.utc(2026, 1, 2, 9, 30),
      );
      final text = ReportExport.toJsonLines([
        report,
        fakeReport(1),
      ], appVersion: '1.2.3');

      final lines = const LineSplitter().convert(text);
      expect(lines, hasLength(2));
      expect(text, endsWith('\n'));
      final first = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(first, {
        'card_id': 'abc',
        'text': 'voluto',
        'pos': 'adj',
        'level': 'C1',
        'gloss': 'a gloss',
        'language': 'it',
        'right': 'voluto',
        'translations': ['one', 'two'],
        'reported_at': '2026-01-02T09:30:00.000Z',
        'app_version': '1.2.3',
      });
      final second = jsonDecode(lines.last) as Map<String, dynamic>;
      expect(second['card_id'], 'id1');
      expect(second['app_version'], '1.2.3');
    });

    test('an accent and a quote stay on their line', () {
      final text = ReportExport.toJsonLines([
        fakeReport(1).copyWith(text: 'é "x"', gloss: 'a\nb'),
      ], appVersion: 'dev');
      expect(const LineSplitter().convert(text), hasLength(1));
    });

    test('no reports is an empty file', () {
      expect(ReportExport.toJsonLines([], appVersion: 'dev'), isEmpty);
    });
  });

  test('fileName is acerta-reports-yyyymmdd-hhmm.jsonl', () {
    expect(
      ReportExport.fileName(DateTime(2026, 1, 2, 9, 5)),
      'acerta-reports-20260102-0905.jsonl',
    );
    expect(
      ReportExport.fileName(DateTime(2026, 11, 15, 23, 59)),
      'acerta-reports-20261115-2359.jsonl',
    );
  });
}

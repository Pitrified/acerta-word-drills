import 'dart:io';

import 'package:acerta/services/reports/report_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../../support/fakes.dart';

void main() {
  late Directory dir;
  late ReportRepository repository;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('acerta_reports');
    Hive.init(dir.path);
    repository = await ReportRepository.open();
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('starts empty', () {
    expect(repository.all, isEmpty);
  });

  test('add keeps one report per word, the latest', () async {
    await repository.add(fakeReport(1));
    await repository.add(fakeReport(2));
    final again = fakeReport(1).copyWith(right: 'other');
    await repository.add(again);
    expect(repository.all.keys, unorderedEquals(['id1', 'id2']));
    expect(repository.all['id1'], again);
  });

  test('all is unmodifiable', () {
    expect(() => repository.all['x'] = fakeReport(1), throwsUnsupportedError);
  });

  test('remove drops one report and ignores an unknown id', () async {
    await repository.add(fakeReport(1));
    await repository.add(fakeReport(2));
    await repository.remove('id1');
    await repository.remove('nope');
    expect(repository.all.keys, ['id2']);
  });

  test('clear drops every report', () async {
    await repository.add(fakeReport(1));
    await repository.add(fakeReport(2));
    await repository.clear();
    expect(repository.all, isEmpty);
  });

  test('the reports survive closing the box', () async {
    final report = fakeReport(
      1,
    ).copyWith(translations: ['a', 'b'], reportedAt: DateTime.utc(2026, 3, 4));
    await repository.add(report);
    await repository.add(fakeReport(2));
    await repository.remove('id2');
    await Hive.box<String>(reportsBoxName).close();
    final reopened = await ReportRepository.open();
    expect(reopened.all, {'id1': report});
    await reopened.clear();
    await Hive.box<String>(reportsBoxName).close();
    expect((await ReportRepository.open()).all, isEmpty);
  });
}

import 'dart:io';

import 'package:acerta/models/word_progress.dart';
import 'package:acerta/services/progress/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

final _t1 = DateTime.utc(2026, 1, 1, 10);
final _t2 = DateTime.utc(2026, 1, 1, 11);

void main() {
  late Directory dir;
  late ProgressRepository repository;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('acerta_progress');
    Hive.init(dir.path);
    repository = await ProgressRepository.open();
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('starts empty', () {
    expect(repository.all, isEmpty);
    expect(repository.of('a'), isNull);
  });

  test('record counts a right and a wrong tap and sets the time', () async {
    await repository.record('a', correct: true, when: _t1);
    expect(
      repository.of('a'),
      WordProgress(seen: 1, correct: 1, lastSeenAt: _t1),
    );
    await repository.record('a', correct: false, when: _t2);
    expect(
      repository.of('a'),
      WordProgress(seen: 2, correct: 1, errors: 1, lastSeenAt: _t2),
    );
  });

  test('all is unmodifiable', () async {
    await repository.record('a', correct: true, when: _t1);
    expect(
      () => repository.all['b'] = const WordProgress(),
      throwsUnsupportedError,
    );
  });

  test('setHidden sets and clears the flag, keeping the counts', () async {
    await repository.record('a', correct: true, when: _t1);
    await repository.setHidden('a', hidden: true);
    expect(repository.of('a')!.hidden, isTrue);
    expect(repository.of('a')!.seen, 1);
    await repository.setHidden('a', hidden: false);
    expect(repository.of('a')!.hidden, isFalse);
  });

  test('setHidden on an unseen word creates its record', () async {
    await repository.setHidden('b', hidden: true);
    expect(repository.of('b'), const WordProgress(hidden: true));
  });

  test('resetCounts keeps hidden and drops the rest', () async {
    await repository.record('a', correct: true, when: _t1);
    await repository.record('b', correct: false, when: _t1);
    await repository.setHidden('b', hidden: true);
    await repository.resetCounts();
    expect(repository.of('a'), isNull);
    expect(repository.of('b'), const WordProgress(hidden: true));
    expect(repository.all.keys, ['b']);
  });

  test('the data survives closing the box', () async {
    await repository.record('a', correct: false, when: _t1);
    await repository.setHidden('b', hidden: true);
    await Hive.box<String>(progressBoxName).close();
    final reopened = await ProgressRepository.open();
    expect(reopened.of('a'), WordProgress(seen: 1, errors: 1, lastSeenAt: _t1));
    expect(reopened.of('b'), const WordProgress(hidden: true));
    await reopened.resetCounts();
    await Hive.box<String>(progressBoxName).close();
    final again = await ProgressRepository.open();
    expect(again.all.keys, ['b']);
  });
}

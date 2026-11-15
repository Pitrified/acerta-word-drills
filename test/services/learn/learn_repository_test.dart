import 'dart:io';

import 'package:acerta/services/learn/learn_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;
  late LearnRepository repository;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('acerta_learn');
    Hive.init(dir.path);
    repository = await LearnRepository.open();
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('starts empty', () {
    expect(repository.all, isEmpty);
  });

  test('add keeps one mark per word, the latest', () async {
    await repository.add('a', DateTime.utc(2026, 1, 1));
    await repository.add('b', DateTime.utc(2026, 1, 2));
    await repository.add('a', DateTime.utc(2026, 1, 3));
    expect(repository.all, {
      'a': DateTime.utc(2026, 1, 3),
      'b': DateTime.utc(2026, 1, 2),
    });
  });

  test('all is unmodifiable', () {
    expect(
      () => repository.all['x'] = DateTime.utc(2026),
      throwsUnsupportedError,
    );
  });

  test('remove drops one mark and ignores an unknown id', () async {
    await repository.add('a', DateTime.utc(2026, 1, 1));
    await repository.add('b', DateTime.utc(2026, 1, 2));
    await repository.remove('a');
    await repository.remove('nope');
    expect(repository.all.keys, ['b']);
  });

  test('the marks survive closing the box', () async {
    final when = DateTime.utc(2026, 3, 4, 5, 6, 7);
    await repository.add('a', when);
    await repository.add('b', when);
    await repository.remove('b');
    await Hive.box<String>(learnBoxName).close();
    final reopened = await LearnRepository.open();
    expect(reopened.all, {'a': when});
    expect(reopened.all['a']!.isUtc, isTrue);
  });

  test('the value is ISO 8601 UTC text', () async {
    await repository.add('a', DateTime.utc(2026, 3, 4, 5, 6, 7));
    expect(Hive.box<String>(learnBoxName).get('a'), '2026-03-04T05:06:07.000Z');
  });
}

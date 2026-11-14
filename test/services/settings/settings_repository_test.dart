import 'dart:io';

import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/services/settings/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;
  late SettingsRepository repository;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('acerta_settings');
    Hive.init(dir.path);
    repository = await SettingsRepository.open();
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('the defaults when nothing is stored', () {
    final settings = repository.read();
    expect(settings.maxLevel, Level.b1);
    expect(settings.pairsPerRound, 5);
    expect(settings.answerLanguage, AnswerLanguage.en);
  });

  test('a written value is read back through a reopened box', () async {
    const written = DrillSettings(
      maxLevel: Level.c1,
      pairsPerRound: 7,
      answerLanguage: AnswerLanguage.it,
    );
    await repository.write(written);
    expect(repository.read(), written);
    await Hive.box<String>(settingsBoxName).close();
    final reopened = await SettingsRepository.open();
    expect(reopened.read(), written);
  });

  test('pairsPerRound is clamped to the bounds', () async {
    await repository.write(const DrillSettings(pairsPerRound: 1));
    expect(repository.read().pairsPerRound, minPairsPerRound);
    await repository.write(const DrillSettings(pairsPerRound: 20));
    expect(repository.read().pairsPerRound, maxPairsPerRound);
  });
}

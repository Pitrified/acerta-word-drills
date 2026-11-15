import 'package:acerta/models/word_progress.dart';
import 'package:acerta/providers/progress_provider.dart';
import 'package:acerta/providers/reports_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late FakeReportRepository reports;
  late FakeProgressRepository progress;
  late FakeFileSaver saver;
  late ProviderContainer container;

  setUp(() {
    reports = FakeReportRepository();
    progress = FakeProgressRepository();
    saver = FakeFileSaver();
    container = ProviderContainer(
      overrides: [
        reportRepositoryProvider.overrideWithValue(reports),
        progressRepositoryProvider.overrideWithValue(progress),
        fileSaverProvider.overrideWithValue(saver),
      ],
    );
    addTearDown(container.dispose);
  });

  ReportsNotifier notifier() => container.read(reportsProvider.notifier);

  test('starts from the repository', () {
    final other = ProviderContainer(
      overrides: [
        reportRepositoryProvider.overrideWithValue(
          FakeReportRepository([fakeReport(1)]),
        ),
      ],
    );
    addTearDown(other.dispose);
    expect(other.read(reportsProvider).keys, ['id1']);
  });

  test('add stores the report and hides the word', () async {
    await notifier().add(fakeReport(1));
    expect(container.read(reportsProvider).keys, ['id1']);
    expect(reports.all.keys, ['id1']);
    expect(progress.of('id1')!.hidden, isTrue);
    expect(container.read(progressProvider)['id1']!.hidden, isTrue);
  });

  test('add keeps the counts of the word', () async {
    await progress.record('id1', correct: true, when: fixedNow);
    await notifier().add(fakeReport(1));
    expect(progress.of('id1')!.seen, 1);
    expect(progress.of('id1')!.hidden, isTrue);
  });

  test('undo removes the report and shows the word again', () async {
    await notifier().add(fakeReport(1));
    await notifier().undo('id1');
    expect(container.read(reportsProvider), isEmpty);
    expect(reports.all, isEmpty);
    expect(progress.of('id1')!.hidden, isFalse);
  });

  test('remove drops the report and leaves the word hidden', () async {
    await notifier().add(fakeReport(1));
    await notifier().add(fakeReport(2));
    await notifier().remove('id1');
    expect(container.read(reportsProvider).keys, ['id2']);
    expect(progress.of('id1'), const WordProgress(hidden: true));
  });

  test('clear drops every report and leaves the words hidden', () async {
    await notifier().add(fakeReport(1));
    await notifier().add(fakeReport(2));
    await notifier().clear();
    expect(container.read(reportsProvider), isEmpty);
    expect(reports.all, isEmpty);
    expect(progress.of('id1')!.hidden, isTrue);
    expect(progress.of('id2')!.hidden, isTrue);
  });

  test('saveToFile writes the reports and returns their count', () async {
    await notifier().add(fakeReport(1));
    await notifier().add(fakeReport(2));
    expect(await notifier().saveToFile(), 2);
    expect(saver.saved, hasLength(1));
    expect(
      saver.saved.single.fileName,
      matches(r'^acerta-reports-\d{8}-\d{4}\.jsonl$'),
    );
    expect(saver.saved.single.text.trim().split('\n'), hasLength(2));
  });

  test('saveToFile returns null when the dialog is cancelled', () async {
    await notifier().add(fakeReport(1));
    saver.accept = false;
    expect(await notifier().saveToFile(), isNull);
    expect(container.read(reportsProvider), hasLength(1));
  });
}

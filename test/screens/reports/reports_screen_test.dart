import 'package:acerta/providers/reports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

Future<void> _open(
  WidgetTester tester, {
  FakeReportRepository? reports,
  FakeProgressRepository? progress,
  FakeFileSaver? saver,
}) async {
  await pumpApp(tester, reports: reports, progress: progress, saver: saver);
  await tapKey(tester, 'home-settings');
  await tapKey(tester, 'settings-reports');
}

void main() {
  testWidgets('says so when there are no reports, with the buttons off', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('No reported pairs.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('reports-save')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('reports-clear')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('lists each report with its word, language and date', (
    tester,
  ) async {
    await _open(
      tester,
      reports: FakeReportRepository([
        fakeReport(1),
        fakeReport(2).copyWith(reportedAt: DateTime(2026, 3, 4, 12)),
      ]),
    );
    expect(find.text('No reported pairs.'), findsNothing);
    final row = find.byKey(const Key('report-row-id1'));
    expect(
      find.descendant(of: row, matching: find.text('w1 - en1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('English · 2026-01-01')),
      findsOneWidget,
    );
    expect(find.text('English · 2026-03-04'), findsOneWidget);
  });

  testWidgets('Remove drops one report and leaves the word hidden', (
    tester,
  ) async {
    final reports = FakeReportRepository([fakeReport(1), fakeReport(2)]);
    final progress = FakeProgressRepository();
    await _open(tester, reports: reports, progress: progress);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('report-row-id1'))),
    );
    await container.read(reportsProvider.notifier).add(fakeReport(3));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('report-row-id3')), findsOneWidget);

    await tapKey(tester, 'report-remove-id1');
    expect(find.byKey(const Key('report-row-id1')), findsNothing);
    expect(find.byKey(const Key('report-row-id2')), findsOneWidget);
    expect(reports.all.keys, unorderedEquals(['id2', 'id3']));
    expect(progress.of('id3')!.hidden, isTrue);
  });

  group('Clear all', () {
    testWidgets('Cancel keeps the reports', (tester) async {
      final reports = FakeReportRepository([fakeReport(1)]);
      await _open(tester, reports: reports);
      await tapKey(tester, 'reports-clear');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(reports.all, hasLength(1));
      expect(find.byKey(const Key('report-row-id1')), findsOneWidget);
    });

    testWidgets('the confirmation removes every report', (tester) async {
      final reports = FakeReportRepository([fakeReport(1), fakeReport(2)]);
      await _open(tester, reports: reports);
      await tapKey(tester, 'reports-clear');
      await tapKey(tester, 'reports-clear-confirm');
      expect(reports.all, isEmpty);
      expect(find.text('No reported pairs.'), findsOneWidget);
    });
  });

  group('Save to file', () {
    testWidgets('writes the reports and says how many', (tester) async {
      final saver = FakeFileSaver();
      final reports = FakeReportRepository([fakeReport(1), fakeReport(2)]);
      await _open(tester, reports: reports, saver: saver);
      await tapKey(tester, 'reports-save');

      expect(saver.saved, hasLength(1));
      expect(saver.saved.single.fileName, endsWith('.jsonl'));
      expect(saver.saved.single.text.trim().split('\n'), hasLength(2));
      expect(find.text('Saved 2 reports'), findsOneWidget);
      expect(reports.all, hasLength(2));
    });

    testWidgets('says "report" for a single one', (tester) async {
      await _open(
        tester,
        reports: FakeReportRepository([fakeReport(1)]),
        saver: FakeFileSaver(),
      );
      await tapKey(tester, 'reports-save');
      expect(find.text('Saved 1 report'), findsOneWidget);
    });

    testWidgets('a cancelled dialog shows nothing', (tester) async {
      final saver = FakeFileSaver()..accept = false;
      await _open(
        tester,
        reports: FakeReportRepository([fakeReport(1)]),
        saver: saver,
      );
      await tapKey(tester, 'reports-save');
      expect(saver.saved, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a platform error says the file could not be saved', (
      tester,
    ) async {
      final saver = FakeFileSaver()..error = PlatformException(code: 'busy');
      final reports = FakeReportRepository([fakeReport(1)]);
      await _open(tester, reports: reports, saver: saver);
      await tapKey(tester, 'reports-save');
      expect(find.text('Could not save the file'), findsOneWidget);
      expect(reports.all, hasLength(1));
    });
  });

  testWidgets('fits a 320 x 568 phone', (tester) async {
    useSmallPhone(tester);
    await _open(
      tester,
      reports: FakeReportRepository([
        for (var i = 0; i < 12; i++) fakeReport(i),
      ]),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byKey(const Key('reports-save'))).dy,
      lessThan(568),
    );
  });
}

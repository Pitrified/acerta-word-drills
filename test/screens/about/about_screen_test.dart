import 'package:acerta/build_info.dart';
import 'package:acerta/data_credit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

void main() {
  setUpAll(registerDataLicenses);

  Future<void> open(WidgetTester tester) async {
    await pumpApp(tester);
    await tapKey(tester, 'home-about');
  }

  testWidgets('shows the name, the version, the source and the credit', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('acerta'), findsOneWidget);
    expect(find.text('dev+local'), findsOneWidget);
    expect(appVersionLabel, 'dev+local');
    expect(find.text(sourceRepoUrl), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('about-source')),
        matching: find.byType(EditableText),
      ),
      findsOneWidget,
    );
    final credit = find.byKey(const Key('about-credit'));
    expect(tester.widget<SelectableText>(credit).data, dataCredit);
    expect(find.textContaining('Pietro Maria Nobili'), findsOneWidget);
  });

  testWidgets('the licenses page lists WordNet 3.0 and the data credit', (
    tester,
  ) async {
    await open(tester);
    await tapKey(tester, 'about-licenses');

    expect(find.text('WordNet 3.0'), findsOneWidget);
    expect(find.text('lang-tools lexical data'), findsOneWidget);
    expect(find.text('dev+local'), findsOneWidget);

    await tester.tap(find.text('WordNet 3.0'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Princeton University'), findsWidgets);
  });

  testWidgets('fits a 320 x 568 phone', (tester) async {
    useSmallPhone(tester);
    await open(tester);
    expect(tester.takeException(), isNull);
  });
}

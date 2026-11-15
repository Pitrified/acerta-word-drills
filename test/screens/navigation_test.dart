import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  for (final (key, title) in [
    ('home-progress', 'Progress'),
    ('home-settings', 'Settings'),
    ('home-about', 'About'),
  ]) {
    testWidgets('home opens $title and Back returns to it', (tester) async {
      await pumpApp(tester);
      await tapKey(tester, key);
      expect(find.widgetWithText(AppBar, title), findsOneWidget);
      expect(find.byKey(const Key('start-round')), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('start-round')), findsOneWidget);
    });
  }

  testWidgets('hidden words open from settings and Back leads home', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapKey(tester, 'home-settings');
    await tapKey(tester, 'settings-hidden');
    expect(find.widgetWithText(AppBar, 'Hidden words'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-round')), findsOneWidget);
  });

  testWidgets('reported pairs open from settings and Back leads home', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapKey(tester, 'home-settings');
    await tapKey(tester, 'settings-reports');
    expect(find.widgetWithText(AppBar, 'Reported pairs'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-round')), findsOneWidget);
  });
}

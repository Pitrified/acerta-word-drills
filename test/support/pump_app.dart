import 'package:acerta/app.dart';
import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/services/cards/card_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Pumps the whole app on fakes and returns its container.
///
/// [progress] and [settings] are the fakes the test can read back.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  CardRepository? cards,
  FakeProgressRepository? progress,
  FakeSettingsRepository? settings,
  DateTime Function()? clock,
  int seed = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: roundOverrides(
        cards: cards ?? fakeCardRepository(12),
        progress: progress ?? FakeProgressRepository(),
        settings: settings ?? FakeSettingsRepository(const DrillSettings()),
        clock: clock,
        seed: seed,
      ),
      child: const AcertaApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(AcertaApp)));
}

/// Taps the widget with the key [key], scrolling it into view first.
Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Sets the screen to a 320 x 568 phone for the rest of the test.
void useSmallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

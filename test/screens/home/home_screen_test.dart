import 'dart:async';

import 'package:acerta/app.dart';
import 'package:acerta/models/answer_language.dart';
import 'package:acerta/models/drill_settings.dart';
import 'package:acerta/models/level.dart';
import 'package:acerta/services/cards/card_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  testWidgets('shows a progress indicator while the words load', (
    tester,
  ) async {
    final loading = Completer<CardRepository>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...roundOverrides(
            progress: FakeProgressRepository(),
            loadCards: () => loading.future,
          ),
        ],
        child: const AcertaApp(),
      ),
    );
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'acerta'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('start-round')), findsNothing);

    loading.complete(fakeCardRepository(12));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('start-round')), findsOneWidget);
    expect(find.text('Start round'), findsOneWidget);
  });

  testWidgets('shows the start button once the words are loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: roundOverrides(
          cards: fakeCardRepository(12),
          progress: FakeProgressRepository(),
          settings: FakeSettingsRepository(const DrillSettings()),
        ),
        child: const AcertaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start-round')), findsOneWidget);
  });

  testWidgets('shows an error when the words cannot be loaded', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...roundOverrides(
            progress: FakeProgressRepository(),
            loadCards: () =>
                Future<CardRepository>.error(UnsupportedCardsFormatError(2)),
          ),
        ],
        child: const AcertaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The words could not be loaded.'), findsOneWidget);
    expect(find.byKey(const Key('start-round')), findsNothing);
  });

  testWidgets('shows the setup with the size of the pool', (tester) async {
    await pumpApp(tester, cards: fakeCardRepository(1893));
    expect(
      tester.widget<Text>(find.byKey(const Key('home-setup'))).data,
      'Up to B1 · 5 pairs · English · 1,893 words',
    );
  });

  testWidgets('the setup follows the settings', (tester) async {
    await pumpApp(
      tester,
      cards: cardRepositoryOf([
        fakeCard(0),
        fakeCard(1, it: const []),
        fakeCard(2, level: Level.c2),
      ]),
      settings: FakeSettingsRepository(
        const DrillSettings(
          maxLevel: Level.a2,
          pairsPerRound: 8,
          answerLanguage: AnswerLanguage.it,
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('home-setup'))).data,
      'Up to A2 · 8 pairs · Italian · 1 word',
    );
  });

  testWidgets('has an entry for progress, settings and about', (tester) async {
    await pumpApp(tester);
    for (final key in ['home-progress', 'home-settings', 'home-about']) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
  });

  testWidgets('shows no setup line while the words load', (tester) async {
    final loading = Completer<CardRepository>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: roundOverrides(
          progress: FakeProgressRepository(),
          loadCards: () => loading.future,
        ),
        child: const AcertaApp(),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('home-setup')), findsNothing);
    expect(find.byKey(const Key('home-settings')), findsNothing);
  });
}

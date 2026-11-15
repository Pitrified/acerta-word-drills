# Project Structure

## Folder layout

```
acerta-word-drills/                   # Flutter project root, package name acerta
  android/                            # Android-specific (mostly generated)
  assets/cards/                       # pt_cards.json, the bundled word cards
  lib/
    main.dart                         # Entry point
    app.dart                          # App widget, router, route paths
    build_info.dart                   # Version label and source address, from --dart-define
    data_credit.dart                  # The data credit and WordNet notice, registered as licenses
    models/                           # Freezed data models (generated)
    providers/                        # Riverpod providers (cards, clock, progress, reports, settings, round, round summary, derived word lists and counts)
    screens/                          # UI screens (one folder per screen)
      home/
      round/                          # RoundScreen, widgets/ (WordTile, RoundSummaryView)
      settings/
      hidden_words/
      progress/
      reports/
      about/
    services/                         # Business logic services
      cards/                          # CardRepository, loads the asset
      logging/                        # AppLogger
      pair_matching/                  # buildRound, gradeTap
      progress/                       # ProgressRepository, Hive box progress
      reports/                        # ReportRepository, Hive box reports; ReportExport, the JSON lines and the save channel
      selection/                      # computeWeight, selectCards
      settings/                       # SettingsRepository, Hive box settings
    utils/                            # Helpers shared by screens (count formatting)
    widgets/                          # Widgets shared by screens (AsyncValueView)
  test/                               # Mirrors lib/
    providers/
    screens/
    support/                          # Fakes shared by the tests: repositories in memory, card builders, the app pump
  integration_test/                   # app_test.dart, the end-to-end run on an emulator
  scripts/                            # check.sh, gates, e2e.sh, build-apk.sh, plans.py
  tool/                               # export_cards.py, writes the card asset
  docs/
  pubspec.yaml
  analysis_options.yaml
```

Folders for further services appear when the first file for them does.

## Layer rules

| Layer | Path | Can depend on | Cannot depend on |
|-------|------|---------------|------------------|
| Models | lib/models/ | Nothing (pure data) | Everything else |
| Services | lib/services/ | Models | Providers, Screens |
| Providers | lib/providers/ | Services, Models | Screens |
| Screens | lib/screens/ | Providers, Models | Services directly |

Widgets used by one screen live in that screen's `widgets/` folder.
`lib/widgets/` and `lib/utils/` hold what more than one screen uses.

Key constraint: screens never import from services directly - they go through providers.

## Naming conventions

| Item | Convention | Example |
|------|-----------|---------|
| Files | snake_case | `home_screen.dart` |
| Classes | PascalCase | `HomeScreen` |
| Providers | camelCase + Provider suffix | `routerProvider` |
| Freezed models | PascalCase | `WordCard` |
| Enums | PascalCase type, camelCase values | `Level.a1` |
| Folders | snake_case | `home/` |
| Test files | same name + _test | `home_screen_test.dart` |

## Generated code

- Freezed output: `*.freezed.dart` and `*.g.dart`
- **Not committed to git** (gitignored)
- Regenerate locally: `dart run build_runner build --delete-conflicting-outputs`

## Package boundaries

Single package with logical layer separation. No multi-package monorepo.

# Project Structure

## Folder layout

```
acerta-word-drills/                   # Flutter project root, package name acerta
  android/                            # Android-specific (mostly generated)
  lib/
    main.dart                         # Entry point
    app.dart                          # App widget, router
    models/                           # Freezed data models (generated)
    providers/                        # Riverpod providers
    screens/                          # UI screens (one folder per screen)
      home/
    services/                         # Business logic services
      logging/                        # AppLogger
  test/                               # Mirrors lib/
    screens/
  scripts/                            # check.sh, gates, build-apk.sh, plans.py
  docs/
  pubspec.yaml
  analysis_options.yaml
```

Folders for models, providers and further services appear when the first file for them does.

## Layer rules

| Layer | Path | Can depend on | Cannot depend on |
|-------|------|---------------|------------------|
| Models | lib/models/ | Nothing (pure data) | Everything else |
| Services | lib/services/ | Models | Providers, Screens |
| Providers | lib/providers/ | Services, Models | Screens |
| Screens | lib/screens/ | Providers, Models | Services directly |

Widgets used by one screen live in that screen's `widgets/` folder.
There is no shared `lib/widgets/` or `lib/utils/` today; create one when a second screen needs the same widget or helper.

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

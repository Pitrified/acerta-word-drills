# acerta-word-drills

**acerta** is an Android app for Portuguese vocabulary drills that work offline.
The words ship inside the app, drills and progress live on the phone, and there is no account.
Pair matching is the first drill.

The tooling and conventions come from [fala-language-tutor](https://github.com/Pitrified/fala-language-tutor), a sibling Flutter app, and from [flutter-setup-project](https://github.com/Pitrified/flutter-setup-project).

## What it does today

- One screen with a placeholder; the drills are not built yet.
- Android only, min API 26, target API 36. Flutter 3.47.7.
- No network access: the release manifest asks for no internet permission.

## Where to look

| Location | What is in it |
|----------|---------------|
| [docs/](docs/) | What the project is now: structure, standards, build and release, privacy |
| [docs/getting-started.md](docs/getting-started.md) | Run the gates and the app |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | The rules an AI assistant works under here |
| [plans/](plans/) | The development diary: how the project got to where it is |

**Docs are the as-is; plans are the diary.**
A decision worth citing lives in the docs file whose topic it is.
The plan folders record how each feature was reasoned about, in the shape the `tracked-development` skill describes, and they are not maintained as documentation.

To read the diary as a list rather than by opening folders:

```bash
python3 scripts/plans.py list                 # every feature, by priority
python3 scripts/plans.py list --status "in progress"
python3 scripts/plans.py list --index 02      # what that folder contains
```

## Gates

```bash
scripts/check.sh          # links, plan folders, codegen, format, analyze, test (-v for full output)
scripts/install-hooks.sh  # once per clone, so a commit runs them too
```

CI runs `scripts/check.sh` and nothing else.
Generated files (`*.freezed.dart`, `*.g.dart`) are gitignored, so a fresh clone needs the codegen gate before anything else will compile.

## License

MIT, see [LICENSE](LICENSE).

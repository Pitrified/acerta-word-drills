# Getting Started

Run the gates and the app.
Setting up Flutter and the Android toolchain from zero, on a workstation or headless, is in
[flutter-setup-project, `docs/getting-started.md`](https://github.com/Pitrified/flutter-setup-project/blob/main/docs/getting-started.md).
This repo pins the Flutter version in `.github/workflows/checks.yml`, and the build box runs the same one.

## Project-specific setup

After cloning this repo:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
scripts/install-hooks.sh   # runs the gates on every commit
flutter run
```

## Gates

`scripts/check.sh` is the one command that runs every check: markdown links resolve,
the plan folders agree with their convention, codegen, `dart format`, `flutter analyze`, `flutter test`.
CI runs the same script, and `scripts/install-hooks.sh` points git at `.githooks` so a
commit runs it too (bypass with `git commit --no-verify`).

```bash
scripts/check.sh                   # one line per gate
scripts/check.sh -v                # every gate's full output
python3 scripts/gates/links.py     # one gate on its own
```

It is quiet by default: one line per gate, being that gate's own summary, and the
full output of any gate that fails. `-v` prints everything.

Gates run in this order: links, plans, codegen, format, analyze, test.
The format gate runs `dart format` over every Dart file git tracks or would add, untracked new files included and gitignored generated files skipped, and fails naming each file it would change.
Fix with `git ls-files -z --cached --others --exclude-standard -- '*.dart' | xargs -0 dart format`.
Codegen is in the list because `*.freezed.dart` and `*.g.dart` are gitignored, so a fresh checkout has
none and analyze fails on every freezed type.
With no freezed or json_serializable input in `lib/`, the codegen gate writes no files and still passes.

**Reproducing CI locally.**
A pass on a working tree proves less than it looks:
the tree has generated files and a warm `.dart_tool` that a CI runner does not.
Clone the repo and run the gates in the clone, which is what CI checks out:

```bash
git clone --no-hardlinks . /tmp/acerta-clean && cd /tmp/acerta-clean
scripts/check.sh
```

## Target versions

| Concern | Value |
|---------|-------|
| Development API level | Android 16 (API 36) |
| Minimum release API | Android 8.0 (API 26) |
| Flutter | 3.47.7 (Dart 3.13.5) |

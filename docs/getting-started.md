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

## The run on an emulator

`scripts/e2e.sh` runs `integration_test/app_test.dart`: the real app on an Android emulator, with the real word asset, real Hive boxes and the real clock.
The widget tests cannot cover that: a `testWidgets` body runs on a fake clock, where a Hive write never completes, so they run on in-memory repositories (`test/support/`).

```bash
scripts/e2e.sh                   # boot the emulator if needed, run, leave it up
scripts/e2e.sh --stop-emulator   # also shut down an emulator this run booted
```

It boots the AVD `fala_api36` headless when `emulator-5554` is not already up (`AVD` and `DEVICE` override both), uninstalls the app so the run starts with no data, and writes `test.log` and `emulator.log` under `build/e2e/`.
With the emulator up and a warm Gradle, a run takes about a minute and a half.
It is not a gate in `scripts/check.sh` and CI does not run it, because it needs an emulator: run it before handing over an APK and after a change to `lib/main.dart`, a repository or a route.

The test is one test in stages, each starting from the state the last one left:
a fresh install with the default settings, a round with one wrong tap, the summary and what the round wrote to the progress box, hiding a word, reporting a pair, a second round with none of the first round's words, the progress screen, a lower level cap and Italian answers, a restart, and the hidden words brought back and the report removed.

`flutter test` on a device removes the app when it ends, so the restart happens inside the run: the test unmounts the app, closes the Hive boxes and calls `main` again, and the new app reads its settings and progress back from the files on the device.
That does not prove the data survives the process being killed.
Check that by hand with a release APK: play a round, `adb shell am force-stop com.acerta.app`, open the app again and look at the progress screen.

## Target versions

| Concern | Value |
|---------|-------|
| Development API level | Android 16 (API 36) |
| Minimum release API | Android 8.0 (API 26) |
| Flutter | 3.47.7 (Dart 3.13.5) |

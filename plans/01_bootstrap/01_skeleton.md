---
status: done
---

# Phase 1 - Repo skeleton and gates

## Overview

An empty app that builds, with fala's tooling around it, so every later phase lands on passing
gates. Sequenced first because it is the lowest risk and everything else needs it.
Context: [`00_start.md`](00_start.md).

## Goals

1. A git repo whose `scripts/check.sh` passes in a clean clone.
2. An app that starts on the emulator and shows one placeholder screen.
3. Instructions and docs that describe this app, not fala.

## Plan

- `git init` straight onto `feat/01_bootstrap`: `main` gets its first commit when the user
  merges or creates it, since a commit on `main` is theirs to make.
- From fala-language-tutor, copied and adapted (names, ids, anything about OpenAI or speech
  removed):
  - `scripts/check.sh`, `scripts/gates/`, `scripts/install-hooks.sh`, `.githooks/`,
    `scripts/plans.py` (the tracked-development skill's copy), `scripts/build-apk.sh`.
  - `.github/workflows/checks.yml`, with the Flutter version of the build box.
  - `analysis_options.yaml`, `build.yaml`, `.gitignore`, `.vscode/`.
  - `android/`, as `com.acerta.app`, label `acerta`, no internet permission in the main
    manifest, the signing fallback and `key.properties.example` kept.
  - `.github/copilot-instructions.md` and a `CLAUDE.md` that imports it, rewritten for this app.
- `pubspec.yaml`: name `acerta`, version `0.1.0+1`, dependencies limited to the stack in
  `00_start.md`.
- `lib/main.dart`, `lib/app.dart`: a Material 3 app, its own seed colour, one home screen, the
  logger from fala.
- One widget test of the home screen.
- Docs: `README.md`, `docs/README.md`, `getting-started.md`, `project-structure.md`,
  `coding-standards.md`, `git-workflow.md`, `build-and-release.md`, trimmed from fala's to
  what is true here. `LICENSE` MIT.
- Verify in a clean clone: `git clone --no-hardlinks . <tmp>` then `scripts/check.sh`.

## Out of scope

- Any word content or drill.
- The GitHub repository: it is created by the user, and the first push is theirs.

## Done when

- `scripts/check.sh` passes in a clean clone.
- `flutter build apk --debug` succeeds.
- No file mentions fala, OpenAI or speech except as a named reference in the docs.

## What the implementation found

- Gradle needs a JDK 17 with a compiler, and the box's default `java` is a 25 runtime without
  one: `scripts/build-apk.sh` sets `JAVA_HOME` to the distro's JDK 17 when it is unset, and
  `docs/build-and-release.md` says so.
- The first build made Gradle download Android NDK r28c, SDK Platform 35 and CMake 3.22.1
  into `~/android-sdk`, outside the repo.
- `unnecessary_await_in_return` is deprecated in Dart 3.13 and fails `flutter analyze`, so it is
  not in `analysis_options.yaml`.
- `scripts/build-apk.sh` passes no version or commit to the app yet: nothing reads them until
  the about screen exists ([`04_screens.md`](04_screens.md)).
- The debug APK is 127 MiB (debug, every ABI); the release size is measured in
  [`05_device_run.md`](05_device_run.md).

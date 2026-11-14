---
status: planned
---

# Phase 5 - Device run

## Overview

The app proven outside the unit tests: an end to end run on the emulator and an APK for the
phone. It stops at the phone (`00_start.md` Q11).
Context: [`00_start.md`](00_start.md), depends on [`04_screens.md`](04_screens.md).

## Goals

1. One scripted run on the emulator plays a round and checks progress after a restart.
2. An APK the user can install.

## Plan

- `integration_test/app_test.dart` and `scripts/e2e.sh`, from fala's, on the existing
  `fala_api36` emulator, without the mock server.
- `scripts/build-apk.sh`: a split release build with the version and commit.
- The keystore: the user creates it under `~/cred/acerta/` by `docs/build-and-release.md`;
  until then the build is debug-signed and says so.
- Hand the APK over; record the size.
- Spin off the follow-ups as draft folders: the GitHub release, the next drills, and whatever
  the first use on the phone turns up.

## Out of scope

- A GitHub release, the Play Store.

## Done when

- `scripts/e2e.sh` passes on the emulator.
- The user has the app on their phone and has played a round.

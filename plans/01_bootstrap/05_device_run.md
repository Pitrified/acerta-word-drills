---
status: in progress
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
  `fala_api36` emulator, without the mock server. One test in stages: a round with one wrong
  tap, the summary, hiding a word, a second round, the settings, the progress screen, then a
  restart.
  `flutter test` on a device removes the app when it ends, so a second run starts empty and
  the restart has to happen inside the one run: the test unmounts the app, closes the Hive
  boxes and calls `main` again. That proves the state is rebuilt from the files on the
  device, not that it survives the process being killed.
- The process kill is checked by hand on the emulator with the release APK: play, force-stop
  the app, open it again, look at the progress screen. The same pass is the first look at
  the screens, by screenshot.
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

## What the implementation found

- `scripts/e2e.sh` passed on its first run: 31 s of Gradle, then 48 s for the test.
  A test that passes first time proves little, so one mutation was run: with the progress
  writes kept out of the Hive box the run fails at the restart stage, where the new app
  reads an empty box instead of ten records.
- The release split build gives an arm64 APK of 20.1 MB and an x86_64 one of 21.6 MB.
  It asks for no permission of its own, internet included; the only entry is the
  `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` that AndroidX adds to every app.
  With no keystore yet it is signed with this box's debug key (`CN=Android Debug`).
  Moving to a keystore-signed build later means uninstalling first, which deletes the progress.
- The process kill, by hand on the emulator with the x86_64 release APK: a round with one
  wrong tap, one word hidden from the summary, `am force-stop`, reopen.
  The progress screen shows 5 words seen and the missed word as "missed 1 of 2", and the
  settings screen counts 1 hidden word.
- The first look at the screens, by screenshot at 1080 x 2400. Everything renders and
  nothing overflows. What a person would notice:
  the board sits in the top third of the screen with tiles as wide as their word;
  the feedback line is at the bottom edge, far from the tiles the eye is on;
  the home screen's upper half is empty.
  None of it is a defect, and all of it is for the first use on the phone to judge.
- Content seen on the way: 3 of the 29,376 glosses end at "e.g." (the WordNet gloss cut at
  its example), and a round can pair a plural or a rare word with a common one
  ("espécies - kind"). Both belong to the corpus, not to this app.
- The release build prints a warning about a missing `CupertinoIcons` font.
  The app uses Material icons only, and the screens show every icon.
- The progress screen's counts had no thousands separator ("29376"); they now go through
  the same formatter as the home screen.

## Still open

- The user installs the arm64 APK and plays a round: the last "Done when" line is theirs.
- The spin-offs (the GitHub release, the next drills, findings from first use) are not
  created: a spin-off is first committed on its own branch cut from `main`, which does not
  exist until the repo is pushed, and its number is the user's to pick. `01` is the only
  number taken.

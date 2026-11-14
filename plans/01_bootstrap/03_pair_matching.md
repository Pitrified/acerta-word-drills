---
status: done
---

# Phase 3 - Pair matching

## Overview

The drill itself: choosing the words, building a round, grading taps, remembering progress,
and the round screen.
Context: [`00_start.md`](00_start.md), depends on [`02_content.md`](02_content.md).

## Goals

1. A learner can play rounds of pair matching end to end.
2. Word choice follows progress, and progress survives closing the app.
3. The logic is tested without a widget, the screen with fakes.

## Plan

- `services/selection/`: the weight of a card given its progress and the weighted draw without
  replacement, from lang-tutor's `progress/selection.py`, same factors, with an injected clock
  and random source.
  The pool is every card under the level cap that is not hidden, instead of the web drill's
  random window: the whole set is in memory, so there is nothing to bound.
- `services/pair_matching/`: the round builder and the tap grader, from lang-tutor's
  `exercises/pair_matching.py`: unique right-hand words, spares, at most one false-friend
  decoy, the trap note as feedback. The right-hand language (English or Italian) is a
  parameter, as `target_language` is there.
- `services/progress/`: per word, seen, correct and error counts, last seen, hidden; in a Hive
  box keyed by lemma id; a repository and a provider.
- The round screen: two columns, tap left then right, a right pair locks, a wrong pair flashes
  and can be retried, the trap note shows when the decoy is tapped, the round ends when every
  pair is locked.
- Tests: the weights against lang-tutor's cases; the round builder (duplicates, spares, decoy, both languages);
  the grader; progress round trip through Hive; a widget test of a full round with a fixed
  random source.
  One mutation check per rule: break the rule, see the test fail, restore.

## Out of scope

- The round summary, settings, progress and about screens (phase 4).
- Any other drill.

## Done when

- A round can be played from the home screen in a widget test of the whole app, and a second
  round avoids the words just seen.
- Progress round-trips through a real Hive box in the repository test.
- `scripts/check.sh` passes.
- The same on the emulator, with the app killed and reopened, is proven by the scripted run of
  [`05_device_run.md`](05_device_run.md): it needs the real app and a real clock, which a
  widget test does not have.

## What the implementation found

- The round reads the level cap, the round size and the answer language, so the settings
  model, its Hive repository and its provider were written here; phase 4 keeps only the
  settings screen.
- "Reset progress" keeps the hidden words hidden: `resetCounts` forgets counts and last seen
  times only.
- Hive writes never complete inside `testWidgets` (fake clock), so the widget tests run on
  in-memory fakes of the two repositories and `lib/main.dart`, which opens the real boxes,
  has no test until the emulator run.
- A missed word comes back rarely at first: its weight is 1 + 3 per error, against 5 for
  each of the thousands of words never seen, and the recency factor holds it back for the
  first hours. The web drill behaves the same. Left as is; a follow-up if it shows on the
  phone.
- The longest trap note is 102 characters, three lines on a small phone, so the feedback
  line has a minimum height and grows instead of a fixed one.

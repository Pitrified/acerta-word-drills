---
status: done
---

# Phase 4 - Screens around the drill

## Overview

What the learner sees outside a round, as answered in `00_start.md` Q5 to Q10.
Context: [`00_start.md`](00_start.md), depends on [`03_pair_matching.md`](03_pair_matching.md).

## Goals

1. The learner can set the level and the round size, read what a round taught, see progress,
   and hide a word.
2. The data credit is visible in the app.

## Plan

- Home: start a round, the current level, links to progress, settings and about.
- Round summary (Q7): each pair with its English gloss, level and look-alike notes (English
  and Italian, whichever side was played), missed
  words marked, "don't show again" per word (Q9), "next round".
- Settings: level cap (Q5), pairs per round (Q6), right-hand language (Q10), hidden words with a way to bring one back
  (Q9), reset progress with a confirmation. The settings model, its Hive repository and its
  provider exist since phase 3; this phase adds the screen.
- Progress (Q8): words seen out of the total per level, the words missed most.
- About: version and commit (`lib/build_info.dart`, filled by `scripts/build-apk.sh` through
  `--dart-define`), the source link as text that can be selected and copied (the app has no
  network permission and opening a browser would need one more dependency for one link), the
  data credit, and the open-source licenses page with the WordNet notice registered in it.
  The credit and the notice are Dart constants; a test holds them equal to the text in
  `DATA_LICENSE.md`, so the two cannot drift.
- Widget tests per screen; `docs/functional-specs.md` written from what was built.

## Out of scope

- Onboarding pages: the defaults (B1, 5 pairs, English) make the first round playable at once.
- Sound, dark theme, any language but English for the interface.

## Done when

- Every screen is reachable from home and back.
- Changing the level changes the words of the next round.
- `scripts/check.sh` passes.

## What the implementation found

- The word count on home and in settings is the pool for the level cap and the answer
  language, hidden words included; `docs/functional-specs.md` says so.
- What a screen shows beyond the stored state (words per level, most missed, hidden words,
  the round as a summary) is computed in providers, so the screens hold no logic and the
  rules are tested without a widget.
- A test that a hidden word stays out of later rounds proves nothing on a fixed clock: a
  word just played already weighs 0 from recency. The test advances the clock a day per
  round.
- Hidden words and ties among the most missed sort by plain string order, so an accented
  first letter sorts after `z`. Left as is.

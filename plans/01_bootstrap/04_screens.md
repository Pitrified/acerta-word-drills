---
status: planned
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
  (Q9), reset progress with a confirmation. Stored in Hive.
- Progress (Q8): words seen out of the total per level, the words missed most.
- About: version and commit, the source link, the data credit from `DATA_LICENSE.md`, the
  WordNet notice, the open-source licenses page.
- Widget tests per screen; `docs/functional-specs.md` written from what was built.

## Out of scope

- Onboarding pages: the defaults (B1, 5 pairs, English) make the first round playable at once.
- Sound, dark theme, any language but English for the interface.

## Done when

- Every screen is reachable from home and back.
- Changing the level changes the words of the next round.
- `scripts/check.sh` passes.

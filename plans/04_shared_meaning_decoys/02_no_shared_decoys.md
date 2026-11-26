---
status: in progress
---

# Phase 2 - No shared decoys

## Overview

The rule and what follows from it: no decoy from a flagged look-alike, and a recap row that
says the shared meaning.
Context: [`00_start.md`](00_start.md) (Q1, Q2, Q4, Q5); depends on
[`01_asset_flag.md`](01_asset_flag.md).

## Plan

1. `decoyWordOf` returns null for a flagged look-alike, in either language (Q1); its doc
   comment says so.
2. The recap row of a flagged false friend says what it shares (Q2):
   `tarde - afternoon, also late (Italian tardi)` when the look-alike's `means` has a lead word
   in the answer language (the lead itself, not through `decoyWordOf`, which now gives none),
   `tarde - afternoon, also Italian tardi` without one; an answer-language flagged full one reads
   `sorte - luck, also sort`.
3. Docs: `docs/drill.md` (the decoys), `docs/functional-specs.md` (the recap row).
4. Measured before and after (Q4) on the real asset, 1,000 seeded 8-pair C2 rounds per
   language: the decoy-slot pool, rounds with a decoy, the share of decoys from the other
   language, no decoy from a flagged look-alike, and how many of the 661 decoys read in
   `03_false_friend_rounds` drop out; logged in `tracking.md`.
5. The open point leaves `plans/open_points.md`.
6. A release APK on the emulator and the file sent for the user's device (Q5).

## Details for the build

- `decoyWordOf` (`lib/services/selection/lookalikes.dart`): a flagged look-alike gives null
  before either branch; `decoyCandidates`, the draw's first slot and `_decoys` need no change.
- `_FalseFriendRow` (`lib/screens/round/widgets/round_summary.dart`) builds
  `'${card.text} - ${right}, not $word'`; for a flagged look-alike it reads `also` instead of
  `not`, and `word` is the look-alike's own text in the answer language, or else the lead of
  its `means` in the answer language with the look-alike named (`late (Italian tardi)`), or else
  the named look-alike alone (`Italian tardi`). The lead is taken even when it is one of the
  card's translations: "also" stays true.
- `docs/drill.md` (the decoy rule, lines on `decoyWordOf`) and `docs/functional-specs.md` (the
  recap row): the wording; the measured numbers in them (`557 cards`, `64%`, `62%`) are updated
  by the main session after the measurement, not by the build.
- `cards_asset_test.dart`: the 8-pair C2 round test also fails on a decoy whose look-alike is
  flagged, and prints the decoy-slot pool size per language (the cards with a decoy candidate).

## Tests

- `lookalikes_test.dart`: a flagged other-language look-alike gives no candidate; a flagged
  answer-language full one neither; an unflagged one still does.
- `selection_test.dart`: a card whose only candidate is flagged is not drawn for the decoy slot.
- `round_summary_test.dart`: the flagged row's wording.
- `cards_asset_test.dart`: over seeded rounds on the real asset, no decoy from a flagged
  look-alike, and every 8-pair C2 round still has one (or the measured exceptions).

## Done when

- `scripts/check.sh` and `scripts/e2e.sh` pass; the measurement is logged.
- The hand-off done (Q5).

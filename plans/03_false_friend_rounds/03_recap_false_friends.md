---
status: planned
---

# Phase 3 - False friends in the recap

## Overview

The round summary gets its own section for the round's false friends, full and partial, so the
lesson the round was built around is in one place.
Nothing changes while matching.
Context: [`00_start.md`](00_start.md) (Q4 to Q8), depends on
[`02_false_friend_slot.md`](02_false_friend_slot.md), which puts one of each kind in the round.

## Current state

- `RoundSummaryView` (`lib/screens/round/widgets/round_summary.dart`) shows a heading, the score,
  then one card per pair.
  Each card lists every look-alike of its word, en and it, full, partial and cognate, with its note,
  all in the same small text: the false friends are there, but mixed with everything else.
- `roundSummaryProvider` builds `RoundSummary` (`entries`, one per pair) from the round, the missed
  set and the progress.
- `PairRound.decoys` holds the decoy that was on the board (`text`, `left`, `note`).
- `falseFriendsIn(card, language, kind)` (`lib/services/selection/lookalikes.dart`) is the test the
  weights, the slots and the decoys already share.

## Plan

1. `lib/models/round_summary.dart`: a `FalseFriendEntry` (the `RoundPair`, the `Lookalike`,
   `onBoard`: whether it was the round's decoy), and `RoundSummary.falseFriends`, a list of them.
2. `roundSummaryProvider`: for each pair in round order, its false friends in both languages
   (Q8), through `falseFriendsIn` so the own-word rule holds: the answer language first, then the
   other, `full` before `partial` within each; `onBoard` when the round's decoy has that `left`
   and that look-alike.
   `Decoy` gets the `Lookalike` it came from: its text is the look-alike's today, and phase 4
   makes it a translation for an other-language false friend, so the text alone cannot say.
3. `RoundSummaryView`: a `False friends` section before the cards, under the score (Q4), one row
   per entry:
   - the pt word, its right word and the look-alike, as `truque - trick, not truck`;
     an other-language look-alike names its language, as `bravo - angry, not Italian bravo`
     (`Lookalike.languageLabel`; phase 4 adds what it means, `00_start.md` Q17);
   - the kind in words (`false friend`, `partial false friend`), and `on the board` when `onBoard`;
   - the note when it has one.
   The section is left out when the list is empty.
   Tapping a row opens the word page, as the cards do (Q7).
4. The cards keep their look-alike lines unchanged (Q6): a false friend shows in the section and
   on its card.
5. The pair order (Q18): `buildRound` (`lib/services/pair_matching/pair_matching.dart`) shuffles
   `pairs` with the round's `Random` once the pairs and the decoys are built, so the reserved
   cards no longer sit at the top of the board, and the board, the summary cards and the section
   all follow the shuffled order. Building still takes the cards in draw order, so the reserved
   cards get their right word first and the first pair with a candidate still gives the decoy.
   Its doc comment says the pairs come back shuffled.
6. Docs: `docs/functional-specs.md`, "Round summary": the section, its order, when it is absent;
   `docs/drill.md`, the line on the summary, if it names what the summary shows, and the slots
   section: the reserved cards are drawn first and shown in a shuffled place.
7. Measured on the real asset: the section's rows per 8-pair C2 round, in en and in it, over
   1,000 seeded rounds each (mean, and the share of rounds with 1, 2, 3, 4 or more rows), through
   the same draw, build and summary code the app runs; logged in `tracking.md`.
   The measure is a test in `test/services/cards/cards_asset_test.dart` that asserts every round
   has at least one row and prints the counts.

## Tests

- `test/providers/round_summary_provider_test.dart`: a round with a full and a partial false
  friend gives two entries, full first; a false friend in the other language is listed too;
  a false friend that is a word of the card's own meaning is not listed (*andar* / *andare*);
  the decoy's entry is `onBoard`, the partial one is not; no false friends gives an empty list.
- `test/screens/round/round_summary_test.dart`: the section shows with its rows and notes before
  the cards; it is absent when the list is empty; tapping a row opens the word page.
- `test/services/pair_matching/pair_matching_test.dart`: over seeded rounds the decoy's card is
  not always the first pair, and the pairs are the same set as before the shuffle; a test that
  reads the pairs in card order compares them as a set instead.
- `integration_test/app_test.dart`: after a round, the summary shows the section (a 5-pair round
  on the real asset always holds a full false friend).

## Out of scope

- Anything on the board while matching, beyond the pair order (Q18).
- Tracking whether the decoy was tapped; `onBoard` says only that it was shown (the user,
  2026-11-26: not now).
- Small rounds.
- The release APK: one hand-off after phase 4 covers both phases (the user, 2026-11-26).

## Done when

- `scripts/check.sh` passes; `scripts/e2e.sh` passes.
- The rows per round are logged in `tracking.md`.

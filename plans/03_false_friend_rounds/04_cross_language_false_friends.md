---
status: done
---

# Phase 4 - False friends in either language

## Overview

A false friend counts whatever its language: the learner knows English and Italian and passes
through both, so an Italian false friend trips them in an English round even though Italian is
not on the board.
The weights and the slots count both languages; the decoy of an other-language false friend is
the answer-language word for what the look-alike mainly means (pt *bravo* "angry", it *bravo*
"good": the decoy is *good*).
Context: [`00_start.md`](00_start.md), "Phase 4" (Q9 to Q13); depends on
[`02_false_friend_slot.md`](02_false_friend_slot.md), on
[`03_recap_false_friends.md`](03_recap_false_friends.md) for the decoy's look-alike, and on
lang-tools `scratch_space/23_false_friend_meanings` (released as `v0.11.0`)
for the words a look-alike means.

## Current state

- `falseFriendsIn(card, language, kind)` and `hasFalseFriendIn(card, language)`
  (`lib/services/selection/lookalikes.dart`) filter by the answer language; the trap factor,
  the two slots of `drawRound` and `_decoys` all go through them.
- `_decoys` (`lib/services/pair_matching/pair_matching.dart`) takes the first `full` false friend
  in the answer language and shows its text.
- A look-alike in the asset carries `language`, `text`, `kind`, `note`: no word for what it means.
- lang-tools `v0.11.0` (2026-11-25) gives each full and partial look-alike `means`: the words of
  its reviewed main sense in the card's other known languages, a map from language to words,
  most frequent first; empty for a cognate, and where that sense has no word.
  The export's card query asks for en and it, so an en look-alike's `means` holds `it` only and
  an it one's `en` only.
- Read from the built `v0.11.0` corpus on 2026-11-26 (a scratch dump of the export's cards, the
  own-word rule applied): in en rounds, 397 it false friends, all with an en word;
  in it rounds, 397 en false friends, 328 with an it word and 69 without (en *exquisite*,
  *baton*, *compliments*).
  pt *bravo*: it *bravo* (partial) means *good*, the user's example.
- A re-export from `v0.11.0` also brings the lang-tools tier C look-alikes: no card is added or
  dropped and no other field changes, but 2,169 cards gain look-alikes:
  39 en and 26 it `full` (197 to 236, 182 to 208), 58 en and 56 it `partial`, and 3,240 cognates,
  which the cognate flag does not read (it compares spellings) but the summary cards list.

## Order

1. lang-tools folder 23: done, released as `v0.11.0` (merged and tagged 2026-11-26).
2. This phase: the export, the app, the tests, the measurements.

## Plan

1. `tool/export_cards.py` writes each look-alike's `means` (the words in the card's other known
   language, lead first), only when it is not empty; the cards `FORMAT` and the app's
   `supportedCardsFormat` go from 2 to 3 together; re-export from lang-tools `v0.11.0`
   (`docs/content.md` updated: the field, the format, the measured counts).
   `Lookalike` gets `means`, a map from language code to words, default empty.
   The tier C look-alikes come with it (Current state), so phase 2's pools are measured again.
2. A card's decoy candidates in a round of answer language L, in `lookalikes.dart` so the draw and
   `_decoys` share them:
   - a `full` look-alike in L: its text, as now;
   - a `full` or `partial` look-alike in the other language (Q13): the lead word of its `means`
     in L, when that word is not a translation of the card in L (Q14; the card's kept
     translations, 4 per language). A look-alike whose lead fails gives no decoy.
   The own-word rule holds for both.
3. The draw (Q15): the trap factor counts a `full` or `partial` look-alike in en or it;
   `drawRound`'s first slot draws from the cards with a decoy candidate, the second (from 5 pairs)
   from the rest with a `partial` look-alike in either language.
4. `_decoys` takes, for the first pair with any, one of its candidates at random (Q12) with the
   round's `Random`, skipping a candidate already a right word of the round or a decoy;
   `maxRoundDecoys` stays 1. A card with no candidate gives no decoy, as now.
5. `Decoy` keeps its look-alike (added in phase 3). A tap on an other-language decoy says
   "False friend! Italian bravo means good." then the note (Q16); an answer-language one is
   unchanged.
6. The recap row of an other-language false friend with a lead word in the answer language
   reads `bravo - angry, not good (Italian bravo)`; without one, the phase 3 row stays (Q17).
7. Docs: `docs/drill.md` (the weight table, "False friends and cognate cards", the slots, the
   decoys, the tap message), `docs/content.md` (the `means` field, the format),
   `docs/functional-specs.md` (the recap row).
8. Measured on the real asset before and after: false-friend pools per answer language, rounds
   with a decoy, the share of decoys from the other language, and 500 other-language decoys read
   for sense (about 700 exist across en and it, so nearly all of them).

## Tests

- `lookalikes_test.dart`: an it false friend counts in an en round; the own-word rule holds in
  both languages; the decoy candidates: an it false friend's lead word in an en round, none when
  the lead is a translation of the card (the next word is not taken), none when `means` has no
  word in L.
- `selection_test.dart`: the trap factor takes an it-only false friend in an en draw; the first
  slot takes only a card with a decoy candidate (an en false friend with no it word is left out
  of an it round's first slot); the second slot takes an it-only partial one in an en draw.
- `pair_matching_test.dart`: an it false friend in an en round gives its lead word as decoy, and a
  tap says "False friend! Italian bravo means good." then the note; a partial it one does too;
  a candidate that is a right word of the round is skipped; over seeded rounds a card with both
  kinds of candidate gives each.
- `round_summary_provider_test.dart` / `round_summary_test.dart`: the other-language row with and
  without a lead word.
- `word_card_test.dart` / the asset parse: `means` read, empty when absent.
- `cards_asset_test.dart`: on the real asset, *bravo* in an en round can give the decoy *good*;
  every 8-pair C2 round in en and in it still has a decoy.

## Out of scope

- More than one decoy per round.
- Small rounds.
- Words lang-tools leaves out of `means` (lang-tools `scratch_space/23_false_friend_meanings/00_start.md`
  Q2): such a look-alike gives a decoy only in rounds of its own language.
- The measurements at levels below C1: the user plays C1 and C2 for now
  (`plans/open_points.md`).
- `means` on the word page: the user reads en and it both (2026-11-26).
- Reporting a decoy: a pair report already carries the card id and the app version, which fix
  the card's decoy candidates (`plans/open_points.md`).

## Done when

- `scripts/check.sh` passes; `scripts/e2e.sh` passes.
- The 500-decoy read is logged in `tracking.md` with how many make sense.
- A release APK on the emulator shows the recap section (phase 3) and an other-language decoy;
  handed to the user for both phases.

## What the implementation found

- Pools at C2 on the re-exported asset: decoy slot 557 en / 394 it (full in the answer language
  alone: 218 / 162), partial slot 323 / 256, any false friend 689 / 567.
- 1,000 seeded 8-pair C2 rounds per language: a decoy in 1,000 en and 999 it rounds; 638 and 620
  of the decoys come from the other language, since most decoy-slot cards have only an
  other-language candidate. The random pick between candidates (Q12) applies within a card only.
- The read of all 661 other-language decoys (`00_start.md`, "The other-language decoys, read"):
  515 make sense; 105 land on a meaning the pt word also has, nearly all from partial look-alikes;
  41 carry a poor lang-tools word. Raised as Q19.
- `computeWeight` and `selectCards` lost their `language` argument: the weight no longer depends on
  the answer language. `hasFalseFriendIn` became `hasFalseFriend` and `hasPartialFalseFriend`.
- `Lookalike` takes `@Freezed(makeCollectionsUnmodifiable: false)` for its map, as `WordCard` does.
- `scripts/e2e.sh` failed twice with "did not complete": the device log shows the host's adb
  connection ending mid-test while the app ran on. A third run passed with no change. The emulator
  (`fala_api36`) and the adb server on port 5037 are shared with other projects on the box (a
  Unity editor compiled 7 s before one drop), so a failed e2e here is checked against
  `build/e2e/` and the device log before it is read as a test result.
- Five mutations caught; `scripts/check.sh` passes with 317 tests.

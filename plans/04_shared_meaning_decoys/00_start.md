---
status: in progress
priority: 0
description: |
  No false-friend decoy from a look-alike whose main meaning the pt word has too (pt tarde
  "afternoon" gets no "late" from it tardi), using the flag lang-tools v0.12.0 puts on each
  look-alike; the recap row says the shared meaning instead of "not".
depends_on: [03_false_friend_rounds]
comment: |
  Picks up the open point "Decoys from a partial false friend that land on a shared meaning"
  (plans/open_points.md), raised in 03_false_friend_rounds (its 00_start.md Q19, answered d).
---

# Shared-meaning decoys - start

## Original note

From `plans/open_points.md`, raised in `03_false_friend_rounds` (Q19, d):
a partial false friend in the other language gives as decoy the first word of what the
look-alike mainly means, and for 104 of the 290 such pairs that is a meaning the pt word also
has (pt *tarde* "afternoon" gets *late* from it *tardi*), so tapping it is not plainly wrong.
lang-tools reviewed every false-friend pair and flags those; this folder re-exports and has the
app give no decoy from a flagged pair.
The user, 2026-11-26: merge lang-tools folder 24 and tag it, "then acerta".

## Current state

- lang-tools `v0.12.0` (merged and tagged 2026-11-26, `c4c82d4`) gives each card look-alike
  `LookalikeHint.shares_meaning`: true when a review found the pt word is also used for the
  look-alike's main meaning (`means`). 293 of the 973 full and partial en and it false friends
  are flagged (269 partial, 24 full); a cognate never is.
  Against the 03 read of 661 other-language decoys: 84 of the 104 "shared" partial decoys are
  flagged, 65 of the 170 partial "good" ones (mostly meanings the pt word does share, which
  that read missed: pt *logo* "logo", pt *sol* "the note G"), 14 of the 345 full "good" ones.
- `tool/export_cards.py` `_lookalike_record` writes `language`, `text`, `kind`, `note`, and
  `means` when not empty; `FORMAT = 3`, matched by the app's `supportedCardsFormat`.
- `Lookalike` (`lib/models/lookalike.dart`) has those fields.
- `decoyWordOf(card, lookalike, language)` (`lib/services/selection/lookalikes.dart`) is the one
  rule for a look-alike's word on the board: a `full` look-alike in the answer language gives
  its own text; one in the other language gives the lead of `means` in the answer language,
  unless that is a translation of the card. `decoyCandidates` (the draw's first slot and
  `_decoys`) and the recap row (`_FalseFriendRow`, `round_summary.dart`) both call it.
- The recap row reads `bravo - angry, not good (Italian bravo)` with a lead word, and
  `bravo - angry, not Italian bravo` without one.

## The approach

- The export writes `shares_meaning` on a look-alike when it is true; the app reads it as
  `Lookalike.sharesMeaning`, default false.
- `decoyWordOf` gives no word for a flagged look-alike, so the draw, the decoys and the recap
  all follow from the one rule.
- The recap row of a flagged false friend says what it shares (Q2).

## Open questions

- Q1: Which decoys does the flag stop?
  - a. Both kinds: an other-language look-alike's `means` word, and an answer-language `full`
    look-alike's own text (pt *sorte* "luck" in an en round would offer *sort*, and pt *sorte*
    is also "a kind"; 24 full pairs are flagged).
  - b. Only the other-language `means` word, the case the open point names.
  - Recommended: a, because the flag says the pt word has the look-alike's main meaning, and
    an answer-language look-alike's own text names that meaning just as its `means` does.
  - ANS: a (the user, 2026-11-26: all as recommended).
- Q2: The recap row of a flagged false friend, which today falls back to
  `tarde - afternoon, not Italian tardi`?
  - a. Say what it shares: `tarde - afternoon, also late (Italian tardi)` with a lead word in
    the answer language, `tarde - afternoon, also Italian tardi` without one.
  - b. Leave the flagged false friend out of the section.
  - c. Keep the fallback row as it is.
  - Recommended: a, because a partial false friend is still worth the recap (the learner
    should know *tarde* is mostly afternoon), and "not" would now be wrong.
  - ANS: a (the user, 2026-11-26: all as recommended).
- Q3: The asset format?
  - a. `FORMAT` and `supportedCardsFormat` from 3 to 4 together, as phase 4 of
    `03_false_friend_rounds` did for `means`.
  - b. No bump: the field is optional and reads false when absent.
  - Recommended: a, because an asset without the flag in an app that reads it would bring the
    shared decoys back silently; the bump makes that a load error.
  - ANS: a (the user, 2026-11-26: all as recommended).
- Q4: The measurement?
  - a. On the real asset, before and after, over 1,000 seeded 8-pair C2 rounds per language,
    as in `03_false_friend_rounds`: the decoy-slot pool, the rounds with a decoy, the share of
    decoys from the other language, and a check that no decoy comes from a flagged look-alike;
    plus the count of the 661 read decoys that drop out.
  - b. a, plus a fresh read of 500 decoys after the change.
  - Recommended: a, because the flags were reviewed in lang-tools (gold 49/50) and the counts
    run over 2,000 rounds; a re-read would read those reviews a second time.
  - ANS: a (the user, 2026-11-26: all as recommended).
- Q5: The hand-off?
  - a. A release APK on the emulator and the file for your device at the end, as for 03.
  - b. No APK; the tests and the measurement only.
  - Recommended: a, because the change is visible in play (fewer, better decoys; new recap
    rows).
  - ANS: a (the user, 2026-11-26: all as recommended).

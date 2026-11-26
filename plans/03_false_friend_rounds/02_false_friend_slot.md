---
status: done
---

# Phase 2 - False-friend slots

## Overview

Every round holds a full false friend, whose decoy shows, and a partial one.
Context: [`00_start.md`](00_start.md), depends on [`01_cognate_cards.md`](01_cognate_cards.md)
for `falseFriendsIn` and the answer language in the draw.

## Plan

1. `drawRound` in `lib/services/selection/selection.dart`, same parameters as `selectCards`
   plus the answer language. Three `selectCards` calls with the usual weights:
   1. one card from the pool cards with a `full` false friend in the answer language;
   2. one card from the rest with a `partial` one;
   3. the rest of the `n` cards from the rest of the pool.

   The reserved cards come first, full then partial. A step whose pool has no card of weight
   above 0 draws nothing, and step 3 draws one more, so the count is always `n` or the pool size.
   A card with both kinds can fill either slot, never both: step 2 draws from what step 1 left.
2. `RoundNotifier.start` calls `drawRound` in place of `selectCards`, with the same
   `pairsPerRound + pairSpares`.
3. `buildRound` is unchanged: it takes cards in order, so the full false friend is the first
   pair and the first card `_decoys` looks at, and `maxRoundDecoys` stays 1.
   The partial one is an ordinary pair; its note shows in the round summary, as now.
4. The partial slot only when the round has 5 pairs or more (`00_start.md` Q3), a constant next
   to `maxRoundDecoys`; under 5 pairs the round has the full slot only.
5. `docs/drill.md`, "The draw": the two slots, their order, the fallback.

## Tests

- `selection_test.dart`, `drawRound`: with both kinds in the pool, every seeded draw holds one
  of each, full first; with none, or all of them hidden, it holds `n` cards from the rest;
  a card with both kinds is drawn once; the count never exceeds `n`;
  a 4-pair round has the full slot and no partial one.
- `round_provider_test.dart`: over 200 seeded rounds on a fake pool with false friends, every
  round has a decoy.
- `cards_asset_test.dart`, the real asset: 1,000 seeded 8-pair C2 rounds in en and in it each
  have a decoy and a partial false friend; a round without a decoy (its text already a right
  word) is counted, and the count stays under 1%.

## Out of scope

- Raising `maxRoundDecoys`, or decoys from partial false friends.
- Tuning small rounds (3 or 4 pairs) beyond dropping the partial slot: a different game, later.
- A re-export of the asset.

## Done when

- `scripts/check.sh` passes; `scripts/e2e.sh` passes.
- A release APK, played on the emulator at C2 with 8 pairs, shows a decoy in each round, and the
  first draw after a cold start is not visibly slower than before; handed to the user.

## What the implementation found

- `drawRound` follows the plan: a `reserve` step per slot over the cards not yet taken, then
  `selectCards` for the rest; `partialSlotMinPairs = 5` sits next to `maxRoundDecoys` in
  `pair_matching.dart`, and `RoundNotifier.start` passes `pairsPerRound >= partialSlotMinPairs`.
- On the real asset, 1,000 8-pair C2 rounds per language: a decoy and a partial false friend in
  every round, 0 rounds without a decoy (the 1% allowance was not needed).
  Three mutations caught; `scripts/check.sh` passes with 296 tests.
- `scripts/e2e.sh` first failed to boot the emulator: `/dev/kvm` is granted by logind to the
  desktop session, and the box was at the login screen. With the desktop logged in it passes.
- Release APK on the emulator, C2, 8 pairs, English: 13 rounds started, each with 8 words and 9
  answers, the decoy on the first card (*tenente* / tenant, *curso* / curse, *lona* / loan,
  *comer* / come, *estância* / stance). Rounds were abandoned rather than played, so nothing was
  recorded and the same word can come back (*declive*, *reunião*, *tenente* twice).
- Cold start to a home screen with the word count, polled through `uiautomator` (about 1 s per
  poll, so a coarse measure): main 3.19 to 3.21 s, this branch 3.19 to 3.25 s over 4 starts each.
  No visible cost from marking the cognate cards at load.

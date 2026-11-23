---
status: planned
---

# Phase 2 - False-friend slots

## Plan

- A function in `lib/services/selection/selection.dart` draws a round's cards in three steps,
  each with `selectCards` and the usual weights:
  1. one card from the pool cards with a `full` look-alike in the answer language;
  2. one card from the rest that have a `partial` look-alike in that language;
  3. `n + 3 - 2` from the rest of the pool.

  The reserved cards come first. A step whose pool is empty (every weight 0) is skipped and its
  card comes from step 3, so a round never shrinks.
- `RoundNotifier.start` calls it in place of `selectCards`.
- `buildRound` is unchanged: it takes cards in order, so the full false friend is the first
  pair and the first to offer a decoy, and `maxRoundDecoys` stays 1.
  The partial one is a normal pair; its note shows in the round summary, as now.
- `docs/drill.md`, "The draw": the two reserved slots and their fallback.

## Tests

- Selection: with both kinds in the pool, every draw holds one of each, first;
  with none, or all hidden, the draw matches `selectCards`; a card with both kinds is taken once.
- Round provider: over many seeded rounds on a pool with false friends, every round has a decoy.
- The real asset: a default en and it round at C2, drawn 1,000 times with a fixed seed,
  has a decoy and a partial false friend every time, except the known limit in `00_start.md`,
  which the test counts.

## Done when

- `scripts/check.sh` passes; a release APK shows a decoy in each round on the emulator
  and is handed to the user.

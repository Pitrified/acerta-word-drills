---
status: planned
---

# Phase 1 - Cognate cards

## The rule

A card is one pt word in one meaning, with that meaning's en and it words.
The user knows both en and it, so a card is trivial when the pt word looks like any word of its
own meaning, in either language, whatever the answer language:

| Card                       | en words     | it words       | Cognate card |
| -------------------------- | ------------ | -------------- | ------------ |
| *andar*, change location   | go, move     | andare         | yes: *andare* |
| *andar*, walk (if it were) | walk         | camminare      | no           |
| *dezembro*, the month      | December     | dicembre       | yes          |
| *carreira*, the occupation | career       | vocazione      | yes: *career* |

The look-alike edges do not decide it: an edge to a word outside the card's meaning says nothing
about the pair on screen, and many plain cognates have no edge (a lang-tools open point).

"Looks like": lowercase, accents stripped, `2 * LCS / (length a + length b)` of 0.7 or more,
LCS being the longest common subsequence.
*dezembro* / *December* 0.75, *andar* / *andare* 0.91, *saúde* / *salute* 0.73;
*nação* / *not* 0.67 is not.
A Levenshtein ratio misses *dezembro* / *December* (0.62); the 0.7 cut was simulated with
Python's `difflib`, which gives the same values on these pairs.

## Plan

- A pure function in `lib/services/selection/` says whether a card is a cognate card,
  comparing its pt word with every word in its `en` and `it` lists.
  The result does not depend on the round, so the card repository computes it once per card.
- `computeWeight`: the cognate factor applies to a cognate card with no false friend;
  `SelectionWeights.cognateFactor` 0.7 -> 0.3.
- The trap factor, and the false-friend slots of phase 2, count a `full` or `partial` look-alike
  in the answer language only, and not one whose text is a word of the card's own meaning:
  the *andar* card carries a `partial` look-alike *andare*, which is its own it word.
- `docs/drill.md`, the weight table: the cognate row describes the cognate card and says 0.3,
  the trap row says "in the answer language".

## Tests

- The ratio: the examples above, an accented pair, a card with an empty it list.
- `test/services/selection/selection_test.dart`: a cognate card is discounted in both answer
  languages; a card with a cognate edge to a word outside its meaning is not; *andar*'s own
  *andare* gives no trap boost; an it false friend gives no boost in an en draw; the 0.3 default.

## Done when

- `scripts/check.sh` passes; the round simulation in `00_start.md`, rerun with the code's
  numbers, gives the cognate cards per 8-pair C2 round, before and after, logged in `tracking.md`.

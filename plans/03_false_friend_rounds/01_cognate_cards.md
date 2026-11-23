---
status: planned
---

# Phase 1 - Cognate cards

## Overview

Fewer trivial pairs: a card whose pt word looks like a word of its own meaning gets a low
weight, and false friends count in the answer language only.
Context: [`00_start.md`](00_start.md).

## The rule

A card is one pt word in one meaning, with that meaning's en and it words.
The user knows both en and it, so a card is trivial when the pt word looks like any word of its
own meaning, in either language, whatever the answer language:

| Card                       | en words     | it words       | Cognate card  |
| -------------------------- | ------------ | -------------- | ------------- |
| *andar*, change location   | go, move     | andare         | yes: *andare* |
| *andar*, walk (if it were) | walk         | camminare      | no            |
| *dezembro*, the month      | December     | dicembre       | yes           |
| *carreira*, the occupation | career       | vocazione      | yes: *career* |

The look-alike edges do not decide it: an edge to a word outside the card's meaning says nothing
about the pair on screen, and many plain cognates have no edge (a lang-tools open point).

"Looks like": lowercase, accents stripped, `2 * LCS / (length a + length b)` of 0.7 or more,
LCS being the longest common subsequence.
*dezembro* / *December* 0.75, *andar* / *andare* 0.91, *saúde* / *salute* 0.73;
*nação* / *not* 0.67 is not.
A Levenshtein ratio misses *dezembro* / *December* (0.62).

On the shipped asset this marks 10,735 of 19,283 cards (56%).
A sample of 100 across the 0.7 to 0.9 band is almost all real cognates
(*emigração* / *emigration*, *conselho* / *consiglio*, *covarde* / *coward*);
the misses are a few chance matches against a minor translation
(*fogo* / it *rogo*, *azar* / *hazard*, *alento* / *alito*).
Under 0.7 there are cognates too (*arquivo* / *archivio* 0.67, *notação* / *notation*),
so the cut is conservative.

## Plan

1. `lib/services/selection/cognate.dart`: `foldWord` (lowercase, accents stripped) and
   `looksAlike(a, b)`, the ratio above with a 0.7 cut; `isCognateCard(card)` compares the
   card's text with every word in its `en` and `it` lists.
   Pure functions, no Flutter import.
2. `WordCard` gets `isCognate`, a field outside the JSON
   (`@JsonKey(includeFromJson: false, includeToJson: false) @Default(false)`), set by
   `CardRepository.parse` with `copyWith(isCognate: isCognateCard(card))`.
   `parse` already runs in an isolate on load, so the 70,699 comparisons are paid once, not
   on every draw; to be timed on the device in phase 2's APK check.
   (`00_start.md` Q1.)
3. `WordCard` gets `falseFriendsIn(AnswerLanguage language, LookalikeKind kind)`:
   its look-alikes of that kind in that language, leaving out one whose folded text is a word
   of the card's own `en` or `it` list (*andar*'s `partial` *andare*).
   `isTrap` and `hasCognate` go; their test in `test/models/word_card_test.dart` is rewritten
   for the new members.
4. `computeWeight` and `selectCards` take `required AnswerLanguage language`:
   - the trap factor applies when `falseFriendsIn` finds a `full` or `partial` one;
   - otherwise the cognate factor applies when `card.isCognate`.
5. `SelectionWeights.cognateFactor` default 0.7 -> 0.1 (`00_start.md` Q2): about 1.4 cognate
   cards per 8-pair C2 round with phase 2's slots, from 4.3.
6. `RoundNotifier.start` passes `settings.answerLanguage`.
7. `_decoys` in `pair_matching.dart` takes its candidates from `falseFriendsIn(language, full)`,
   so a decoy and the trap factor agree on what a false friend is.
8. Docs: `docs/drill.md`, the weight table (the trap row "in the answer language", the cognate
   row the cognate card and its factor) and a short section on the cognate rule;
   `docs/content.md` if it describes `WordCard` fields.

## Tests

- `test/services/selection/cognate_test.dart`: the ratios above, an accented pair, a card with
  an empty `it` list, *andar* "go" a cognate card and a "walk / camminare" card not.
- `test/models/word_card_test.dart`: `falseFriendsIn` by kind and language, the own-word case.
- `test/services/selection/selection_test.dart`: a cognate card is discounted in both answer
  languages; a card with a cognate edge only (no look-alike word in its meaning) is not;
  an it false friend gives no boost in an en draw; the new default factor.
- `test/services/cards/cards_asset_test.dart`: on the real asset, *dezembro* and the *andar*
  card are cognate cards, and the share of cognate cards is between 40% and 70% (a guard
  against the rule silently matching all or nothing, loose so a re-export does not break it).

## Out of scope

- The false-friend slots (phase 2).
- Any lang-tools change: the missing cognate edges are its open point.

## Done when

- `scripts/check.sh` passes.
- The round simulation in `00_start.md`, rerun with the code's rule, logs the cognate cards per
  8-pair C2 round before and after in `tracking.md`.

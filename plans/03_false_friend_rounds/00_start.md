---
status: done
priority: 0
description: |
  Rounds that teach false friends: fewer cognates, which are trivial pairs (andar - andare),
  and a false-friend decoy in every round.
comment: |
  Raised by the user on 2026-11-23, after counting the false friends on the lang-tools cards.
---

# False-friend rounds - start

## Original note

The user, on 2026-11-23: "ok now we work on acerta
1. less cognates (andar andare -> trivial, lower percentage)
2. more false friends -> at least one per batch shown"

## Current state

Measured on the shipped asset (lang-tools `v0.10.1`, 19,283 cards), read-only.

The selection factors look at the look-alikes of every language, not of the answer language:
a card with an it cognate gets the 0.7 discount in an en round, where its answer is not trivial,
and a card with an it false friend gets the 1.3 boost in an en round, where no trap shows.

Decoys come only from `full` look-alikes in the answer language, and only when such a card is drawn.

A default round (up to B1, 5 pairs, a new learner), simulated over 20,000 rounds:

| Answer | Cognates per round | Rounds with a false friend | Rounds with a decoy |
| ------ | -----------------: | -------------------------: | ------------------: |
| en     | 1.27 of 5          | 39%                        | 20%                 |
| it     | 1.90 of 5          | 36%                        | 16%                 |

With the factors on the answer language only and the cognate factor at 0.3:
0.63 (en) and 1.03 (it) cognates per round, and 43% of rounds with a false friend.
Weights alone do not reach every round.

Cards up to B1 with a `full` look-alike in the answer language: 56 for en, 41 for it.
With partial ones: 122 and 103.

The user plays with the level at C2, where the picture differs (10,000 rounds, 5 pairs):

| Answer | Pool   | Full / any false friend | Cognates per round, now / phase 1 | Rounds with a decoy |
| ------ | -----: | ----------------------: | --------------------------------: | ------------------: |
| en     | 19,283 | 192 / 362               | 0.44 / 0.20                       | 7%                  |
| it     | 14,085 | 146 / 282               | 0.66 / 0.30                       | 8%                  |

At C2 the cognates are already few; the decoy is what is missing, so phase 2 carries the change.
The current lang-tools corpus has 230 en and 201 it full false friends on its pt cards
(the tier C rebuild); how many of those pass the export's card floor is not measured.

The user plays 8 pairs at C2 and sees more than one cognate per round.
Most of them carry no look-alike: counting pairs whose pt word and right word have a spelling
ratio of 0.7 or more (`difflib`, lowercase, accents stripped), an 8-pair C2 round holds

| Answer | Labelled cognate in that language | Pair looks alike | Of which with no look-alike |
| ------ | --------------------------------: | ---------------: | --------------------------: |
| en     | 0.67                              | 2.30             | 1.98                        |
| it     | 1.07                              | 2.92             | 2.40                        |

(*dezembro* / *December*, *acesso* / *access*, *semana* / *settimana*, *pouco* / *poco*).
The lang-tools look-alike generator misses them; that is a lang-tools open point,
"Plain cognates the look-alike generator misses".

## Decisions (the user, 2026-11-23)

- **Cognates**: a card is a cognate card when its pt word looks like any en or it word of its
  own meaning, whatever the answer language, since the user knows both
  (*andar* "go" / *andare* is one; *andar* "walk" / *camminare* would not be).
  Look-alike edges do not decide it. The cognate factor goes from 0.7 to 0.3
  (reopened by Q2 below: under this rule 56% of the cards are cognate cards; answered 0.1).
  The flag is computed once when the cards load (Q1).
- **False friends** count in the answer language only, and not when the false friend is a word
  of the card's own meaning.
- **False friends in every round, both kinds**: two slots of the round are drawn, with the usual
  weights, one from cards with a `full` look-alike in the answer language (its decoy shows) and
  one from cards with a `partial` one.
  A slot whose pool is empty (all hidden, or a level with none) is drawn as now.
  The partial slot only from 5 pairs up (Q3); small rounds are a different game, to be tuned
  separately, not here.
- No asset re-export in this folder:
  the lang-tools tier C rebuild adds few full false friends up to B1 (63 en in the corpus against 56 in the asset).

## Known limits

- The false-friend pools at C2, leaving out a false friend that is a word of the card's own
  meaning: 184 full and 134 partial for en, 143 and 116 for it
  (the own-word rule drops 8 en / 3 it full ones and 37 en / 22 it partial ones, *andar* / *andare*
  among them). Up to B1 the full pool is about 56 en / 41 it, so a low level cap brings the same
  ones back often; the one-hour recency damping spaces them a little.
  Widening the pools means more reviewed false friends in lang-tools.
- The reserved card's decoy is skipped when its text is already a right word of the round;
  the round then has no decoy unless another drawn card supplies one.
- The cognate check compares with every word of the card's meaning, so a minor translation can
  make a chance match (*fogo* / it *rogo*, *azar* / *hazard*); a few in a 100-card sample.

## Review (2026-11-23)

The plan checked against the code before execution.

- Claims checked: the selection factors read `WordCard.isTrap` / `hasCognate`, which look at every
  language; `_decoys` takes the first `full` look-alike in the answer language; `buildRound` takes
  cards in order, so a reserved first card is the first pair; `CardRepository.parse` runs in an
  isolate; pairs per round go from 3 to 8 (`drill_settings.dart`); the real-asset tests read
  `assets/cards/pt_cards.json` (`cards_asset_test.dart`). All hold.
- Measured, the rule on the shipped asset: 10,735 of 19,283 cards (56%) are cognate cards.
  Cognate cards per 8-pair C2 round, with the two slots: 4.3 now (no slots), 2.4 at factor 0.3,
  1.4 at 0.1, 1.1 at 0.05, in either answer language; about 0.6 to 0.7 of them are the slot cards
  themselves (a false friend in one language that looks like its word in the other).
- Corrected in the sub-plans: the cognate flag is computed once at load rather than per draw
  (70,699 comparisons); `_decoys` uses the same false-friend test as the weights; phase 1's file
  is renamed to its phase, `01_cognate_cards.md`.

## Open questions

- Q1: Where is a card's cognate flag computed? The rule needs the card's own words only.
  - a. In the app, once in `CardRepository.parse` (the load isolate), kept on `WordCard` as a
    field outside the JSON.
  - b. In the lang-tools export tool, as a field of the card asset; needs a re-export and a
    format bump.
  - c. In the app, on every draw: about 70,000 short comparisons per round.
  - Recommended: a, because it needs no re-export, costs nothing per round, and the rule stays
    next to the weights it feeds.
  - ANS: a.
- Q2: Which cognate factor? 56% of cards are cognate cards, so 0.3 still leaves about 2.4 in an
  8-pair round (from 4.3 now).
  - a. 0.3, about 2.4 per round.
  - b. 0.1, about 1.4 per round.
  - c. 0.05, about 1.1 per round.
  - Recommended: b, because it brings cognate cards near one a round, which is what the user
    asked for, while keeping them in the drill; c gains little over it.
  - ANS: b.
- Q3: The two slots in a small round: pairs per round can be 3, where two slots make two thirds of
  the round false friends.
  - a. Both slots at every size.
  - b. The full slot always; the partial slot from 5 pairs up.
  - Recommended: b, because a 3-pair round with two traps is mostly traps, and the decoy, the
    part that teaches, is kept.
  - ANS: b. "But really it's a different game at such low pairs, to be tuned differently;
    also we do not care much right now about that." So b as a stopgap, and small rounds are
    not tuned in this folder.

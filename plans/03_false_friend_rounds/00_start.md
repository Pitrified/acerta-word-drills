---
status: planned
priority: 1
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
  Look-alike edges do not decide it. The cognate factor goes from 0.7 to 0.3.
- **False friends** count in the answer language only, and not when the false friend is a word
  of the card's own meaning.
- **False friends in every round, both kinds**: two slots of the round are drawn, with the usual
  weights, one from cards with a `full` look-alike in the answer language (its decoy shows) and
  one from cards with a `partial` one.
  A slot whose pool is empty (all hidden, or a level with none) is drawn as now.
- No asset re-export in this folder:
  the lang-tools tier C rebuild adds few full false friends up to B1 (63 en in the corpus against 56 in the asset).

## Known limits

- The full false-friend pool is 192 en / 146 it at C2, but only 56 / 41 up to B1, so a low
  level cap brings the same ones back often; the one-hour recency damping spaces them a little.
  Widening the pool means more reviewed false friends in lang-tools, or partial ones in the slot.
- The reserved card's decoy is skipped when its text is already a right word of the round;
  the round then has no decoy unless another drawn card supplies one.

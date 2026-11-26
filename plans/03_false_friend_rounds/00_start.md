---
status: in progress
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
  Look-alike edges do not decide it. The cognate factor goes from 0.7 to 0.3
  (reopened by Q2 below: under this rule 56% of the cards are cognate cards; answered 0.1).
  The flag is computed once when the cards load (Q1).
- **False friends** count in the answer language only, and not when the false friend is a word
  of the card's own meaning.
  (Reopened by Q9, the user on 2026-11-25: false friends in either language trip the learner,
  who passes through Italian in an English round; phase 4 makes the change.)
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

## Phase 3, the recap (the user, 2026-11-25)

After playing the APK: "partial false friends, and full false friends, should have a dedicated
section in the recap, like before or after the cards. not while matching in the main round."
Done in this folder, as phase 3: [`03_recap_false_friends.md`](03_recap_false_friends.md).
The same day: cognates fine, rounds "pretty hard now", repeats accepted, Italian fine,
small rounds not relevant now.

- Q4: Where does the false-friends section go in the summary?
  - a. Before the cards, under the score.
  - b. After the cards, above Next round and Home.
  - Recommended: a, because it is the lesson of the round and is read before scrolling through
    eight cards; after them it sits below the fold.
  - ANS: a, before the cards.
- Q5: Which false friends does it list?
  - a. Those in the round's answer language only, by the test the slots use (own-word rule
    included): usually two, the decoy's and the partial one.
  - b. Both languages: every full and partial look-alike of the round's words.
  - Recommended: a, because it lists what the round was built around and stays short;
    b adds the other language's traps, which the round did not play.
  - ANS: "those that are false friends? unclear question". Not answered; asked again as Q8.
- Q6: The cards still list every look-alike. With the section, what do the cards show?
  - a. Unchanged: the false friends show twice, in the section and on their card.
  - b. The cards drop the look-alikes the section lists, and keep the rest (cognates, the
    other language).
  - Recommended: a, because the card is the full record of the word and the change stays
    small; b is easy to add if the repeat bothers.
  - ANS: a, keep.
- Q7: Does a row of the section open the word page when tapped, as the cards do?
  - a. Yes.
  - b. No, plain text.
  - Recommended: a, because it is the same gesture as the cards and costs one `InkWell`.
  - ANS: a, tappable.
- Q8 (Q5 asked again): Q5 was unclear. A card can have false friends in English, in Italian, or
  both (63 cards have both: *comprimento*, en *compliments*, it *complimento*; *novela*, en *novel*,
  it *novella*). The round shows answers in one language, the answer language of the settings,
  and the slots are filled from false friends in that language (Decisions, "False friends").
  In an English round, which false friends does the section list?
  - a. The English ones of the round's words: the decoy's card and the partial slot's card,
    sometimes another drawn card. *comprimento* shows *compliments* only.
  - b. English and Italian ones of the round's words: *comprimento* shows both, and a card drawn
    for its English answer can bring an Italian false friend the round never played.
  - Recommended: b, because the user knows both languages and an Italian look-alike misleads as much
    as an English one (*comprimento* / *complimento*); the section is a recap, not a board, so
    showing what was not played costs only a line or two.
  - ANS: b, both.

## Phase 4, false friends in either language (the user, 2026-11-25)

"They do not trip me because I do not see them on the board (Italian is not there), but they
trip me if I still pass through Italian. [...] so like bravo / angry / arrabbiato: the false
friend is in Italian, bravo / good: we show good as trap."

So the answer-language rule of the Decisions goes: a false friend in English or Italian counts,
for the weights and the slots, and the decoy of an Italian false friend in an English round is
the English word for the Italian look-alike's meaning (pt *bravo* "angry", it *bravo* "good":
the decoy is *good*). The other way round in an Italian round.
Phase 4: [`04_cross_language_false_friends.md`](04_cross_language_false_friends.md).

Measured on the shipped asset (read-only): of the full and partial look-alikes, a lookup of the
look-alike's text in `pt_meanings.json` (meanings holding that en or it word) finds words in the
other language for 182 of 197 en full, 147 of 174 en partial, 175 of 182 it full and 160 of 175
it partial ones.
The words found are often right (it *burro* gives *butter*, it *complimento* gives *compliment*)
and sometimes noisy: the meanings are those of pt words, so it *bravo* gives *brave, courageous,
good, respectable* and it *novella* gives *yarn, narration, recital, news*.

- Q9: Do false friends count in either language? (Reopens the Decisions line above.)
  - ANS: yes, the user on 2026-11-25, quoted above.
- Q10: Where does the decoy word of an other-language false friend come from?
  - a. In the app, from `pt_meanings.json`: the meanings that hold the look-alike's text in its
    language, and their words in the answer language. No re-export; the word is a guess where
    the look-alike has several meanings (it *bravo*).
  - b. From lang-tools: the export writes, on each look-alike, its translations in the other
    language, taken from the look-alike lemma's own senses (or from the review, which already
    knows what the look-alike means, as its notes show). Needs a lang-tools change, a re-export
    and a format bump; the words come from the look-alike's meaning, not from pt meanings.
  - c. a now, b later as a lang-tools open point.
  - Recommended: b, because the decoy is the word the learner is trapped into, and a wrong one
    (*yarn* for *novella*) teaches nothing; a only works by accident of which pt meanings exist.
  - ANS: "we do it well, plan the change cross with lang-tools if needed": b. The main meaning of each look-alike word is a reviewed best-sense pin in lang-tools, and the card's look-alike carries its words in the other language (`means`); lang-tools `scratch_space/23_false_friend_meanings`, on its branch `feat/23_false_friend_meanings`. Measured there: 1,085 known words, 798 with two or more senses; it senses have no frequency of their own, so they tie.
- Q11: Which decoy word when the look-alike has several translations (it *bravo*: good, brave,
  skilled)?
  - a. The first, in the order the source gives (frequency, under b).
  - b. The first that is not a right word or a translation of the card itself.
  - Recommended: b, because a decoy equal to a translation of the card would be a right answer.
  - ANS: b.
    (Reopened by Q14 on 2026-11-26: the lead word only, since the words after it are near-synonyms
    of the right answer.)
- Q12: A card with false friends in both languages (*comprimento*: en *compliments*, it
  *complimento*): which one gives the decoy?
  - a. The answer-language one, as now; the other language only when the card has none.
  - b. Either, at random.
  - Recommended: a, because it is the trap on the board in its own form, and phase 2's numbers
    stay as measured.
  - ANS: b, at random: "when selecting a false friend it can be both the pt/en or the pt/it->en one. Both are valid options."
- Q13: Can a partial other-language false friend give a decoy? Today a partial false friend never
  does, since its look-alike shares a meaning with the pt word and tapping it would not be wrong.
  Across languages the decoy is a translation, not the look-alike: for *bravo* (it, partial) the
  decoy *good* is not a meaning of pt *bravo*, so it is wrong to tap.
  - a. Yes, when the decoy word is not a translation of the card (Q11's check).
  - b. No, full ones only, as in the answer language.
  - Recommended: a, because *bravo*, the user's example, is partial, and Q11's check keeps out
    the shared meaning.
  - ANS: a.

## Review of phases 3 and 4 (2026-11-26)

Both drafts checked against the code before execution, with lang-tools `v0.11.0` released.

- Claims checked, all hold: `RoundSummaryView` shows the heading, the score, then one card per
  pair listing every look-alike; `roundSummaryProvider` builds the entries from the round, the
  missed set and the progress; `Decoy` holds `text`, `left`, `note`, nothing of the look-alike;
  `falseFriendsIn` filters by language and applies the own-word rule, and the trap factor,
  `drawRound`'s two slots and `_decoys` all go through it; the export's card query asks for en and
  it, so `means` comes through with the other language only; the test files the plans name exist.
- Measured on a scratch dump of the export's cards from the built `v0.11.0` corpus (nothing
  written in this repo): the numbers in `04_cross_language_false_friends.md`, Current state.
  The re-export brings the tier C look-alikes too, 65 more full false friends and 3,240 more
  cognates, so the Decisions line "no asset re-export" ends with phase 4.
  The folder's "798 words with two or more senses" (Q10) was read from the curated file;
  lang-tools counts 664 on the built corpus.
- Corrected in the sub-plans: phase 4's Current state and Order (lang-tools done), the export
  writes `means` only when not empty and the format goes from 2 to 3, the decoy read is 500
  (the 500-item rule for assessments), the lang-tools Q2 reference names its file;
  phase 3's entry order within a pair and the language label in a row.

- Q14: Which `means` word is the decoy? (Reopens Q11, on the numbers.) Q11 answered "the first word
  that is not a right word or a translation of the card". When the lead word is a translation of the
  card, the trap leads the learner to a right answer, and the next word is mostly a near-synonym of
  it: pt *largo* (it *grande*), en *large* means *grande, grosso*: the decoy would be *grosso*;
  *forte* gives *rocca*, *campo* gives *accampamento*, *jornal* gives *diario*.
  The lead is a translation of the card for 7 look-alikes in en rounds and 16 in it rounds.
  - a. The lead word only: when it is a translation of the card, that look-alike gives no decoy.
    Cards with a decoy candidate: 556 en, 394 it.
  - b. The first word that passes, as Q11 answered: 558 en, 403 it.
  - Recommended: a, because a word past the lead is not what the look-alike mainly means, so it is
    no trap; it costs 2 en and 9 it cards of the pool.
    The check reads the card's kept translations (4 per language); one en lead is a translation
    beyond the 4 and slips through, a known limit.
  - ANS: a.
- Q15: Which cards does each slot draw from in phase 4? The full slot exists so the round has a decoy
  (phase 2); the plan's step 2 makes both slots count any false friend in en or it, and then the
  first card can be one with no decoy (an en false friend with no it word, in an it round).
  - a. The decoy slot draws from the cards with a decoy candidate (a `full` look-alike in the answer
    language, or an other-language false friend whose lead word passes Q14); the partial slot from
    the rest with a `partial` look-alike in either language. The trap factor counts any false friend
    in either language.
  - b. As drafted: the full slot from cards with a `full` look-alike in either language, the partial
    slot from a `partial` one in either language.
  - Recommended: a, because it keeps phase 2's promise of a decoy in every round; the decoy pool grows
    from 218 to 556 cards in en and from 195 to 394 in it.
  - ANS: a. The user: "why are we filling decoy from a first slot anyway? is the decoy always for the first card shown?"; asked as Q18.
- Q16: What does a tap on an other-language decoy say? Today: "False friend! <note>", where the note is
  the lang-tools note on the pt word and its look-alike. On *bravo* / *good* the learner sees *good*,
  not *bravo*, so the note alone may not say where *good* comes from.
  - a. "False friend! Italian bravo means good." then the note.
  - b. The note only, as for an answer-language decoy.
  - Recommended: a, because it names the step through Italian, which is the trap.
  - ANS: a.
- Q17: The recap row of an other-language false friend, once `means` is in the asset (phase 3 shows
  `bravo - angry, not Italian bravo`):
  - a. Phase 4 adds the lead word: `bravo - angry, not good (Italian bravo)`; with no lead word in the
    answer language, the phase 3 row stays.
  - b. The phase 3 row stays.
  - Recommended: a, because the row then shows the trap word as it was or would be on the board.
  - ANS: a.
- Q18: The reserved cards sit at the top of the board. `drawRound` puts the first slot's card first
  and the partial slot's second, `buildRound` keeps that order, and the board lists the left column
  in pair order (`round_screen.dart`), so the decoy belongs to the top word, every round, and the
  partial false friend is the second. The slot itself is needed: at C2, weights alone reach a decoy
  card in 7 to 8% of rounds. Its place is the leak.
  (Phase 2's release check, "each with a decoy on its first card", saw it and took it for the slot
  working.)
  - a. `buildRound` shuffles the pairs with the round's `Random` once they and the decoys are built,
    so the board, the summary and the recap follow the shuffled order. Building keeps the reserved
    cards first, so they still get their right word before the others.
  - b. Shuffle only the left column on the board, keeping `pairs` in draw order.
  - Recommended: a, because one order serves the board and the summary alike; done in phase 3,
    before the recap is built on the pair order, and cheap: one `shuffle` and a test that over
    seeded rounds the decoy's card is not always first.
  - ANS: a, "shuffle it".

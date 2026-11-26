# Drill

How the pair matching drill chooses words, builds a round, grades a tap and remembers the result.
The rules are those of the lang-tutor web drill, ported to Dart.
The logic lives in `lib/services/selection/`, `lib/services/pair_matching/`, `lib/services/progress/` and `lib/services/settings/`.
`roundProvider` drives it and `lib/screens/round/` shows it; see [The round on screen](#the-round-on-screen).

## The pool

A round draws from every card that:

- is at or under the level cap of the settings,
- has at least one translation in the answer language,
- has none of its topics in the off topics of the settings; a card with no topic always passes,
- is not hidden.

The whole card set is in memory, so the pool is not sampled down first.
The clock and the random source are parameters of every function that uses them; the app supplies them through `clockProvider` and `randomProvider`.

## The weight of a card

`computeWeight` gives each card a weight; the draw picks cards in proportion to it.
The factors multiply, starting from a base of 1.

| Rule | Factor |
|------|--------|
| Hidden | The weight is 0 and the card is never drawn |
| Never graded (no record, or `seen` is 0) | 5 |
| Graded | 1 + 3 per error |
| Level | A1 1.3, A2 1.2, B1 1.1, B2 1.0, C1 0.9, C2 0.8 |
| Has a false friend, English or Italian (see below) | 1.3 |
| A cognate card (see below) with no false friend | 0.1 |
| Last seen at some time | 1 - 0.5 ^ (elapsed / 1 hour), elapsed never below 0 |

The recency factor is 0 at the moment a word is graded, 0.5 an hour later and 0.75 after two hours, so a word just seen is not drawn again at once.
A last seen time in the future counts as elapsed 0.
The numbers are the defaults of `SelectionWeights`.

### False friends and cognate cards

The rules are in `lib/services/selection/lookalikes.dart`.

A false friend of a card is a `full` or `partial` look-alike, English or Italian, whatever the answer language:
the learner knows both and passes through both, so an Italian false friend misleads in an English round too (pt *bravo* is "angry", it *bravo* "good").
A look-alike that is itself one of the card's own English or Italian words is no false friend of that card:
the *andar* card means "go", *andare*, so its partial look-alike *andare* is left out.
The weights, the slots, the decoys and the summary use the same test.

A card is a cognate card when its Portuguese word looks like one of its own English or Italian words, whatever the answer language,
since the learner knows both: *andar* "go" with *andare*, *dezembro* with *December*.
The look-alikes of the card play no part, because a look-alike may name a word outside the card's meaning, and many plain cognates have none.
Two words look alike when, in lower case and without accents, twice the length of their longest common subsequence over the sum of their lengths is at least 0.7:
*dezembro* and *December* give 0.75, *não* and *not* 0.67.
About half the cards are cognate cards, so their factor is low, to keep them near one a round.
`CardRepository` marks the cognate cards once, when it is built, so a draw does not compare words.

## The draw

A round of `n` pairs draws `n + 3` cards, the spares being there so that a card dropped while pairing does not shrink the round.
`drawRound` makes the draw, with false friends first (below); each of its steps is a `selectCards`, which draws without replacement:

1. A card with a repeated id or a weight of 0 is left out.
2. Each draw takes `r = random * total weight` and walks the running sum of the weights, taking the first card whose running sum exceeds `r`.
3. The drawn card leaves the pool and the next draw starts again, up to `n + 3` cards or the end of the pool.

The cost of a draw is linear in the pool size, with no sort.

### False-friend slots

`drawRound` reserves the first cards of a round for false friends, then fills the rest with `selectCards`:

1. One card from the cards that can give a decoy in the answer language (`decoyCandidates`, below), so the round can show one.
2. From 5 pairs up (`partialSlotMinPairs`), one card from the rest with a partial false friend, English or Italian.
   A smaller round is mostly traps with both, so it gets the full one only.
3. The other cards from the rest of the pool.

Each step draws with the same weights.
A step with no card of weight above 0 (no such false friend at the level cap, or all of them hidden or just seen) draws nothing, and the last step draws one more, so the round keeps its size.
A card with both kinds fills one slot only.
Since `buildRound` takes the cards in order, the decoy card is the first pair built and the first to offer a decoy.
On the real asset at C2 the decoy slot draws from 449 cards in English and 330 in Italian, the partial slot from 323 and 256.
The pairs are then shuffled, so the reserved cards have no fixed place on the board.

## Building the round

`buildRound` takes the drawn cards in order.

- It stops at the pair count from the settings.
- A card whose Portuguese text is already a left word is skipped.
- The right word of a card is its first translation in the answer language that no other pair uses, compared in lower case.
  A card with no such translation is skipped.
- A round with fewer than 2 pairs is not built and `buildRound` returns null.
- Once the pairs and the decoy are built, the pairs are shuffled with the round's random, so the pair order of the board and the summary is not the draw order.
- A reserved card can still be skipped, when its translations are all taken by earlier cards (*negro* and *preto* share their only Italian one, *nero*); a few rounds in a thousand lose their partial false friend that way.

### Decoys

A round holds at most one decoy.
A false friend gives a decoy word in a round answered in language L (`decoyWordOf`):

- a `full` one in L, its own text;
- a `full` or `partial` one in the other language, the first word of what it mainly means in L (its `means`, from lang-tools): it *bravo* gives *good* for pt *bravo* in an English round.
  None when that word is a translation of the card, since the trap then leads to a right answer; the words after it are near-synonyms of the right one (en *large* means *grande*, *grosso* for pt *largo*), so they are not taken either.
  None when it has no word in L (en *exquisite* has none in Italian).
- A `partial` one in L, none: it shares an everyday meaning with the Portuguese word and tapping it would not be wrong.
- None from a look-alike that shares meaning (`Lookalike.sharesMeaning`, a lang-tools review flag), in either language and whatever its kind: the Portuguese word is also used for what the look-alike mainly means, so tapping it would not be wrong (pt *tarde* is "afternoon" and also "late", it *tardi*).

Going through the paired cards in draw order, the first card with a decoy word not already a right word or a decoy (in lower case) gives the decoy; a card with several gives one of them at random.
On the real asset, in 8-pair C2 rounds, about 58% of the decoys of an English round come from Italian and 57% of an Italian round's from English; 1 English and 2 Italian rounds in 1,000 have none.
The decoy joins the right column and matches nothing.
Tapping it for the word it is a false friend of shows `False friend!` and the look-alike's note, when the note is not empty.
A decoy from the other language first names its look-alike, as `False friend! Italian bravo means good.`, then the note, note or not.
Tapping it for any other word, or any other wrong tap, shows `Wrong pair.`.
A decoy keeps the look-alike it came from, which the summary reads to mark it `on the board`.

The right column is the right words and the decoy texts, shuffled.

## What a tap records

`gradeTap` marks a tap correct when the right word is exactly the pair's right word for the left word.
Every graded tap adds one to `seen` and one to `correct` or `errors` for the left word, and sets its last seen time.
A tap on a left word that is not in the round records nothing, because the result carries no card id.

## Progress

`ProgressRepository` keeps one record per word in the Hive box `progress`: the key is the card id and the value is the JSON text of a `WordProgress` (`seen`, `correct`, `errors`, `last_seen_at`, `hidden`).
The decoded records are held in memory and every change is written to the box before it returns.
A word without a record is a word never graded.

| Operation | Effect |
|-----------|--------|
| `record` | `seen` + 1, `correct` + 1 or `errors` + 1, last seen set |
| `setHidden` | Sets the hidden flag, keeping the counts |
| `resetCounts` | Forgets the counts and last seen time of every word and keeps the hidden flags; a word that is not hidden loses its record |

`progressProvider` exposes the records as state and refreshes it with a new map after each operation.
`main` has to override `progressRepositoryProvider` with an opened repository; reading it without an override throws `ProviderNotOverriddenError`.

## Reports

`ReportRepository` keeps one report per word in the Hive box `reports`, apart from the progress: the key is the card id and the value is the JSON text of a `WordReport`.
Resetting the progress leaves the reports alone.
A report holds what was on screen: the card id, the Portuguese text, part of speech, level and gloss, the answer language, the right word of the round, every translation of the card in that language, and the time of the report.
The decoded reports are held in memory and every change is written to the box before it returns.

| Operation | Effect |
|-----------|--------|
| `add` | Stores the report, replacing the one of the same word |
| `remove` | Drops the report of one word |
| `clear` | Drops every report |

`reportsProvider` wraps the repository like the progress provider.
Its `add` also hides the word, `undo` removes the report and unhides the word, and `remove` and `clear` leave the words hidden.
`main` has to override `reportRepositoryProvider` with an opened repository.
The file the reports are saved to is in [content.md](content.md#the-reports-file).

## Words to learn

`LearnRepository` keeps the words the learner marked in the Hive box `learn`, apart from the progress: the key is the card id and the value is the time of the mark as ISO 8601 UTC text.
Resetting the progress leaves the marks alone.
The decoded marks are held in memory and every change is written to the box before it returns.

| Operation | Effect |
|-----------|--------|
| `add` | Marks a word at a time, replacing an earlier mark |
| `remove` | Drops the mark of one word |

`learnProvider` wraps the repository like the reports provider; its `add` stamps the mark with the clock in UTC.
`learnWordsProvider` joins the marks with the cards by id, newest mark first, and skips an id that is no longer in the card set.
A mark has no effect on selection or rounds.
`main` has to override `learnRepositoryProvider` with an opened repository.

## Settings

`SettingsRepository` keeps the `DrillSettings` as JSON text under the key `drill` of the Hive box `settings`.

| Setting | Default | Bounds |
|---------|---------|--------|
| `maxLevel` | B1 | A1 to C2 |
| `pairsPerRound` | 5 | 3 to 8; a stored value outside is clamped when read |
| `answerLanguage` | English | English or Italian |
| `offTopics` | none | The topics whose words a round leaves out; a topic that is not listed is on |

When the key is absent, or a stored value lacks a field, the defaults apply.
`settingsProvider` exposes the settings and writes each change through; `settingsRepositoryProvider` is overridden by `main` in the same way as the progress one.

## The round on screen

`roundProvider` holds a `RoundState`: the status, the `PairRound`, the selected left and right word, the locked words of each side, the wrong pair still marked, the feedback text and the ids of the cards missed in this round.
The provider is not auto-disposed, so a finished round stays readable until the next one starts.

The status is one of:

| Status | Meaning |
|--------|---------|
| `loading` | `start` is drawing the words; also the state before the first round |
| `playing` | A round is on screen with pairs left to match |
| `notEnoughWords` | The pool could not fill a round of at least 2 pairs; the screen offers Home |
| `finished` | Every pair is locked; the screen shows the round summary, with Next round and Home |

`start` reads the settings, the progress, the clock and the random source, draws `pairsPerRound + 3` cards from the pool and builds the round.
A hidden word weighs 0, so it is never drawn and the pool is not filtered a second time.

The tap rules:

- Taps work in either order, left word first or right word first.
- A tap on a locked word is ignored and changes nothing.
- Tapping the selected word again deselects it.
- Tapping another word on the side that has a selection moves the selection.
- Every tap that is not ignored clears the wrong mark and the feedback of the previous wrong tap.
- When both sides are selected the pair is graded with `gradeTap` and the selection is cleared.
  A correct pair is locked.
  A wrong pair is marked until the next tap, the feedback is set from the result, the card id joins the missed set, and the pair stays playable.
- Taps do nothing unless the status is `playing`.

The state changes first and the progress is written after, so the screen does not wait for the box.
Each graded tap whose result has a card id is recorded once, correct or not, with the time from `clockProvider`.
Selecting or deselecting a word records nothing.
The round is finished when every pair is locked; wrong taps do not end it.

The screen shows the Portuguese words in the pair order of the round on the left and the right column on the right, both scrolling together.
The feedback line and the two columns sit together at the bottom of the screen, above the system navigation bar, with the feedback directly above the tiles: a thumb reaches the tiles without covering it.
A longer note grows upwards, so the tiles do not move, and a round taller than the screen scrolls as a whole.
Every tile is as wide as its column.
A tile is idle, selected, locked (disabled) or wrong, drawn with the theme colours.
The tiles have the keys `left-<text>` and `right-<text>`, and the feedback line `round-feedback`.

When the round is finished the board gives way to the summary, built by `roundSummaryProvider` from the round, the missed set and the progress.
It holds one entry per pair in round order, each flagged missed (its card id is in the missed set) and hidden (its progress record has the hidden flag), and the count of pairs never missed.
It also lists the round's false friends (`falseFriendEntries`): pair by pair, the full and partial look-alikes of each word in both languages, through `falseFriendsIn`, so a look-alike that is a word of the card's own meaning is left out; the answer language first, full before partial; each flagged `onBoard` when the round's decoy came from it.
On the real asset an 8-pair C2 round lists about 3 of them (3.05 in English, 3.23 in Italian, never fewer than 2).
Hiding a word from the summary calls `setHidden` on the progress, so the word has weight 0 from the next round on, and `Hidden, undo` restores it.
Reporting a pair from the summary adds a `WordReport` to the reports and calls `setHidden` the same way; `Reported, undo` removes the report and unhides the word.
Removing a report from the reported pairs screen, or clearing them all, leaves the words hidden.
Marking a word with `Learn this` adds it to the learn marks and nothing else; `To learn, undo` removes the mark.
The title of an entry adds the first translation in the answer language that is not the round's, when the card has one.
What the summary shows is in [functional-specs.md](functional-specs.md#round-summary).

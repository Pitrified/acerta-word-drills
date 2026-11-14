# Drill

How the pair matching drill chooses words, builds a round, grades a tap and remembers the result.
The rules are those of the lang-tutor web drill, ported to Dart.
The logic lives in `lib/services/selection/`, `lib/services/pair_matching/`, `lib/services/progress/` and `lib/services/settings/`.
`roundProvider` drives it and `lib/screens/round/` shows it; see [The round on screen](#the-round-on-screen).

## The pool

A round draws from every card that:

- is at or under the level cap of the settings,
- has at least one translation in the answer language,
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
| Has a false friend (a `full` or `partial` look-alike) | 1.3 |
| Has a cognate and no false friend | 0.7 |
| Last seen at some time | 1 - 0.5 ^ (elapsed / 1 hour), elapsed never below 0 |

The recency factor is 0 at the moment a word is graded, 0.5 an hour later and 0.75 after two hours, so a word just seen is not drawn again at once.
A last seen time in the future counts as elapsed 0.
The numbers are the defaults of `SelectionWeights`.

## The draw

A round of `n` pairs draws `n + 3` cards, the spares being there so that a card dropped while pairing does not shrink the round.
`selectCards` draws without replacement:

1. A card with a repeated id or a weight of 0 is left out.
2. Each draw takes `r = random * total weight` and walks the running sum of the weights, taking the first card whose running sum exceeds `r`.
3. The drawn card leaves the pool and the next draw starts again, up to `n + 3` cards or the end of the pool.

The cost of a draw is linear in the pool size, with no sort.

## Building the round

`buildRound` takes the drawn cards in order.

- It stops at the pair count from the settings.
- A card whose Portuguese text is already a left word is skipped.
- The right word of a card is its first translation in the answer language that no other pair uses, compared in lower case.
  A card with no such translation is skipped.
- A round with fewer than 2 pairs is not built and `buildRound` returns null.

### Decoys

A round holds at most one decoy.
Going through the paired cards in order, the first look-alike with kind `full`, in the answer language and whose lower case text is not already a right word or a decoy, becomes a decoy.
A partial false friend is never a decoy, because it shares an everyday meaning with the Portuguese word and tapping it would not be wrong.
The decoy joins the right column and matches nothing.
Tapping it for the word it is a false friend of shows `False friend!` and the look-alike's note, when the note is not empty.
Tapping it for any other word, or any other wrong tap, shows `Wrong pair.`.

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

## Settings

`SettingsRepository` keeps the `DrillSettings` as JSON text under the key `drill` of the Hive box `settings`.

| Setting | Default | Bounds |
|---------|---------|--------|
| `maxLevel` | B1 | A1 to C2 |
| `pairsPerRound` | 5 | 3 to 8; a stored value outside is clamped when read |
| `answerLanguage` | English | English or Italian |

When the key is absent the defaults apply.
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
A tile is idle, selected, locked (disabled) or wrong, drawn with the theme colours.
The tiles have the keys `left-<text>` and `right-<text>`, and the feedback line `round-feedback`.

When the round is finished the board gives way to the summary, built by `roundSummaryProvider` from the round, the missed set and the progress.
It holds one entry per pair in round order, each flagged missed (its card id is in the missed set) and hidden (its progress record has the hidden flag), and the count of pairs never missed.
Hiding a word from the summary calls `setHidden` on the progress, so the word has weight 0 from the next round on, and `Hidden, undo` restores it.
What the summary shows is in [functional-specs.md](functional-specs.md#round-summary).

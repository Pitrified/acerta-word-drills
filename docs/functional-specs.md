# Functional specs

What the app does, screen by screen.
The rules of the drill itself (the pool, the weights, the draw, grading, what is stored) are in [drill.md](drill.md) and are not repeated here.
The words and their fields are in [content.md](content.md).

The interface is in English.
Every screen except home has an app bar with a back button, so home is reachable from each of them.

## Home

Home shows the app name, then, once the words are loaded:

- One line with the current setup, such as `Up to B1 · 5 pairs · English · 1,893 words`: the level cap, the pairs per round, the answer language and the number of words in the pool for that cap and language.
  The count does not exclude hidden words.
- The Start round button.
- Entries for Progress, Settings and About.

While the words load home shows a spinner, and if they cannot be loaded it says `The words could not be loaded.`.

## Round

Start round draws a round from the current settings and opens the round screen, where the pairs are matched as described in [drill.md](drill.md#the-round-on-screen).
When the pool cannot fill a round the screen says `Not enough words for a round at this level.` and offers Home.

## Round summary

When every pair is matched the round screen shows the summary in place of the board.
It has a heading, `Round done`, and a line such as `4 of 5 right first time`: the pairs never missed out of all the pairs.

Below that is one card per pair, in round order:

- The Portuguese word and the right word that was played, then the first translation of the word in the other answer language when it has one: `estudo - work - studio` in an English round, the English word after the Italian one in an Italian round.
  A word with no translation in the other language shows the two parts only.
- The level and the part of speech.
- The English gloss, whatever the answer language.
- Every look-alike of the word, English and Italian: its language, its text, its kind in words (`false friend`, `partial false friend` or `cognate`) and its note when it has one.
- A `missed` mark when the word was matched wrongly at least once in the round.
- The part of the card above the buttons (title, level, gloss, look-alikes) is tappable and opens the [word page](#word-page); back returns to the summary.
- A `Don't show again` button, which hides the word.
  A hidden word shows `Hidden, undo` in its place, which brings it back.
  The button follows the stored progress, so it reads the same after the screen is rebuilt.
- A `Report pair` button beside it, for a pair the data gets wrong.
  It stores the report and hides the word; its label then reads `Reported, undo`, which removes the report and shows the word again.
  The `Don't show again` button of a reported word reads `Hidden, undo` like any hidden word.
  A word hidden by hand is not reported.
- A `Learn this` button, which adds the word to the words to learn; its label then reads `To learn, undo`, which takes the word off the list.
  It does not hide the word or change the rounds.
  The three buttons sit in one right-aligned row and wrap on a narrow screen.

The list scrolls.
Next round and Home stay at the bottom of the screen: Next round starts another round, Home returns to the home screen.

## Settings

Every change is written at once.

- Level cap, A1 to C2, as a row of options that wraps on a narrow screen.
- Pairs per round, 3 to 8, on a slider with the current number beside it.
- Answer language, English or Italian, with a line under it saying how many words at or under the level cap have a translation in the chosen language.
- Topics, under the answer language: a chip for each topic of the words, most words first, with the number of words of the topic, such as `Medical 417`.
  All are on at first; a chip that is off removes the words of that topic from the rounds and from the count lines, and a word with two topics goes when either is off.
  A line under the chips says `Words with no topic are always included.`.
- Hidden words, with their count; it opens the hidden words screen.
- Reported pairs, with their count; it opens the reported pairs screen.
- Words to learn, with their count; it opens the words to learn screen.
- Reset progress, which asks for confirmation: the counts of every word are forgotten and hidden words stay hidden.
  Cancel changes nothing; Reset clears the counts and shows `Progress reset`.
  The reported pairs and the words to learn are kept.

## Hidden words

The hidden words sorted by text, each with its first English translation and a Restore button.
With none hidden the screen says `No hidden words.`.
An id in the progress that is no longer in the card set is left out.

## Words to learn

The words marked with `Learn this`, newest mark first.
Each row shows the Portuguese word, with its first English translation, its first Italian translation and its level under it, separated by `·`; a translation the word does not have is left out.
Tapping a row opens the [word page](#word-page) of the word.
Each row has a Remove button, which removes the word and does not open the page.
With none the screen says `No words to learn.`.
An id that is no longer in the card set is left out.

## Word page

Opened from the round summary and from a row of the words to learn; back returns to where it came from.
The words are not tappable: the page is one step from the card and has no further links.
The app bar title is the Portuguese word.
Under it the page shows the word, then its level and part of speech.
The meanings load from their own asset the first time a page opens, with a spinner meanwhile; when the asset cannot be read the page says `The meanings could not be loaded.`.
A word the cards or the meanings do not know shows `No details for this word.`.

`This meaning` is the meaning of the card:

- Its English gloss, and its Portuguese gloss under it when the corpus has one.
- `Also in Portuguese`, `In English` and `In Italian`: the words that express the meaning, as chips such as `vocação · B2`.
  The level is the level of the word in this meaning, and is left out when the asset gives none.
  The card's own word is left out of the Portuguese words.
  A language with no word left is not shown; with none left in any language the section says `No other words for this meaning.`.

`Other meanings` are the other meanings of the same Portuguese word, most frequent first:

- Each shows the level of the word in that meaning, the English gloss, the Portuguese gloss when there is one, and its words in Portuguese, English and Italian, with the same rules as above.
  A meaning with no other word says `No other words.`.
- The first five show.
  When there are more, `Show all (N)` shows the rest; it is not folded again until the page is closed.
- With none the section says `No other meanings.`.

## Reported pairs

The reports from the round summary, oldest first.
Each row reads `<Portuguese word> - <right word>`, with the answer language and the date of the report under it, and has a Remove button.
Removing a report does not show the word again; that is done from the hidden words screen or with `Reported, undo` on the summary.
With none the screen says `No reported pairs.`.

Two buttons stay at the bottom, both off while there is no report:

- Save to file opens the Android dialog for a new file, named like `acerta-reports-20261115-0930.jsonl`, and writes every report to it.
  The learner chooses the folder.
  It shows `Saved <n> reports` (`Saved 1 report` for one), nothing when the dialog is cancelled and `Could not save the file` when writing fails.
  Saving keeps the reports.
- Clear all removes every report after a confirmation; the words stay hidden.
  The file is described in [content.md](content.md#the-reports-file).

## Progress

- For each level from A1 to C2, `<seen> of <total> words seen` with a progress bar.
  A word is seen when it has at least one graded tap; a word that was only hidden is not.
  The total of a level is the number of cards at exactly that level.
- A total line over all levels.
- Most missed: up to 10 words with at least one error, most errors first and ties by text, each with its first English translation and its error and seen counts.
  With none the screen says `No missed words yet.`.

An id in the progress that is no longer in the card set is left out of both.

## About

- The app name and the version label, such as `0.1.0+1a2b3c4d`; a build made without the two defines of [build-and-release.md](build-and-release.md#version-label) shows `dev+local`.
- The address of the source repository, as selectable text.
  The app has no network permission and opens no links.
- The data credit of [DATA_LICENSE.md](../DATA_LICENSE.md), as selectable text.
- An Open-source licenses button, which opens the licenses page of Flutter.
  The page lists the packages of the app, `WordNet 3.0` with the WordNet license notice, and `lang-tools lexical data` with the data credit.
  Both are registered at start from `lib/data_credit.dart`, and `test/data_credit_test.dart` checks that they match `DATA_LICENSE.md`.

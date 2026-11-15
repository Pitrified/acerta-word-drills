---
status: in progress
---

# Phase 8 - Words to learn, and the other language in the summary

## Overview

After the report button the user asked for three more things.
Two of them are app-only and come here: a mark for words the learner wants to learn, and
the translation in the other answer language on the summary.
The third, a topic picker with medical words off, needs topics in the word asset, which
first need a medical topic and a commonness floor in lang-tools (`20_rare_words_topics` in
lang-tools, on `feat/20_rare_words_topics`); the picker is
[`09_topic_picker.md`](09_topic_picker.md).
Context: [`00_start.md`](00_start.md).

## Decisions

Functional, from the user:

- The mark is "just a list": a button on the summary card adds the word to a list of words
  to learn; rounds do not change.
- The summary title shows the other language's first translation after the right word,
  `estudo - work - studio`; when the card has none in the other language, the title stays
  as it is now.

Technical:

- The marks are their own Hive box, `learn`, keyed by card id, value the time of the mark
  as ISO 8601 text, like the reports box and apart from the progress, so a progress reset
  keeps them.
- The list screen reads the cards by id from the card repository, like the hidden words
  screen, so it shows current card data and skips an id that left the asset.
- The other language is the one that is not the round's answer language
  (`AnswerLanguage.values`), so the rule holds both ways: English rounds show the Italian,
  Italian rounds show the English.

## Plan

- `LearnRepository` (open, all, add, remove), opened in `main`; `learnProvider` with a
  notifier; a fake for the tests.
- Summary card: a third button, `Learn this`, reading `To learn, undo` once marked.
  The three buttons share the right-aligned wrap.
- Summary title: `<pt> - <right>` plus ` - <first translation in the other language>` when
  there is one.
- Settings: a `Words to learn` row with the count, opening a screen that lists the words
  newest mark first: Portuguese word, first English and first Italian translation when
  present, level; each with Remove.
- Tests: repository round trip; mark and undo from the summary; the title with and without
  the other language, in an English and an Italian round; the list, its order, Remove,
  a missing card id skipped; the reset keeps the marks; navigation.
- e2e: a stage marks a word, checks it in the list and after the restart.
- Docs: `docs/functional-specs.md`, `docs/drill.md`.
- A new APK from the commit.

## Out of scope

- Any effect of the mark on rounds.
- Topics.

## Done when

- `scripts/check.sh` and `scripts/e2e.sh` pass.
- On the emulator with the release build: a word marked from the summary is in the list,
  and an English round's summary shows the Italian word where the card has one.

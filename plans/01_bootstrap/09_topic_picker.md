---
status: in progress
---

# Phase 9 - Topic picker

## Overview

The user asked to remove medical terms through a general topic picker, keeping relatively
common ones ("cortisone or lung is ok, atelectasia is not").
The topics, the medical topic and the commonness floor were made in lang-tools
(`20_rare_words_topics` in lang-tools, on `feat/20_rare_words_topics`, release 0.8.0), which
also raised the two upper CEFR edges so C2 is no longer every rare-ish word.
Context: [`00_start.md`](00_start.md).

## Decisions

Functional, from the user:

- Settings lists the topics as chips, all on by default, medical included; turning one off
  removes its words from rounds, and medical off removes every medical word; words with no
  topic always stay. The rare medical words never reach the asset, through the commonness
  floor of lang-tools.

Technical:

- The export asks lang-tools for cards whose meaning has a frequency of at least zipf 2.0
  (`CardQuery.min_zipf`) and writes each card's `topics`; the asset format goes to 2 and the
  app refuses format 1.
- The off topics are a set in `DrillSettings`, stored with the other settings, so a new
  topic in a later asset starts on.
- A card is drawn when none of its topics is off.
- The chips are the topics present in the asset, most words first, each with its word
  count, so a topic with no word never shows.

## Plan

- `tool/export_cards.py`: `MIN_ZIPF = 2.0`, `topics`, `FORMAT = 2`; the asset re-exported
  from the 0.8.0 corpus: 18,210 cards, 4,881,493 bytes (1,328,357 with `gzip -9`); A1 330,
  A2 516, B1 1,029, B2 2,664, C1 5,508, C2 8,163; 27 topics, `medical` on 395 cards;
  6,515 cards with no topic.
- `WordCard.topics`; `supportedCardsFormat = 2`; the card repository's pool filter takes
  the off topics; the pool counts on settings follow it.
- `DrillSettings.offTopics` with a setter on the notifier; the settings screen gets a
  Topics section of filter chips under the answer language.
- Tests: the format check, the topics parse, the pool with a topic off (a card with an off
  topic out, a card with two topics out if either is off, a card with none in), the chips
  and their counts, the setting stored and read back, the round level cap still holding.
- e2e: medical off in the settings stage; the next round holds no medical card; the
  setting survives the restart.
- Docs: `docs/content.md` (format 2, `topics`, the floor, the new size and counts),
  `docs/functional-specs.md` (the Topics section), `docs/drill.md` (the pool rule).
- A new APK; on the emulator, medical off and a round looked at.

## Out of scope

- The progress screen's per-level totals stay the whole asset, not the pool.
- Topic names translated or grouped: they are lang-tools' names, capitalized.

## Done when

- `scripts/check.sh` and `scripts/e2e.sh` pass.
- On the emulator with the release build: the Topics chips show, medical off, and a round
  without medical words.

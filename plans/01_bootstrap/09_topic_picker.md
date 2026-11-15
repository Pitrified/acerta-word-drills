---
status: draft
---

# Phase 9 - Topic picker

## Overview

The user asked to remove medical terms through a general topic picker, keeping relatively
common ones ("cortisone or lung is ok, atelectasia is not").
The topics and the commonness floor are content, so they are made in lang-tools first
(`20_rare_words_topics` in lang-tools, on `feat/20_rare_words_topics`).
This phase starts when that one has a corpus with a medical topic.
Context: [`00_start.md`](00_start.md).

## Decisions

Functional, from the user:

- Settings lists the topics as chips, all on except medical; turning one off removes its
  words from rounds; words with no topic always stay.

## Plan

- `tool/export_cards.py`: each card carries the topics of its card concept; the asset
  format version goes up by one.
- The card model, the pool filter (a card is drawn when none of its topics is off), the
  settings model and screen, the counts on the settings and progress screens.
- Tests, e2e stage, docs, a new APK.

## Out of scope

- Making the topics themselves: lang-tools.

## Done when

- To be written when the lang-tools corpus is ready.

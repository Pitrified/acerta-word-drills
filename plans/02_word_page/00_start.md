---
status: in progress
priority: 1
description: |
  A word page, opened from the round summary and the words to learn list: every meaning
  the Portuguese word has, and every other word for the card's meaning in pt, en and it,
  each with its level. One step from the card, no further browsing.
comment: |
  Raised from the "carreira - calling - vocazione" card on 2026-11-15, after the user asked
  why "calling"; the ranking issue itself is a lang-tools open point.
---

# Word page - start

## Original note

The user, on 2026-11-15: "we want to be able to navigate the wordnet a tiny bit more:
1. knowing the alternatives in pt - all the possible meanings of carreira in portugues;
2. knowing the other ways to express the current card meaning, both in pt (are there
other options for this meaning in pt aside from carreira, like vocacao?) and in
english/italian (vocation/calling/career) (vocazione). Clarify these concepts before
implementing the ui."

## The two directions

lang-tools models a word (lemma), a meaning (concept, one WordNet synset, with a gloss) and
a sense, the link between a word and a meaning that carries the level and frequency.

1. **A word's meanings**: the senses of the word. *carreira* has four: the B1 card meaning
   "the particular occupation for which you are trained", and B2 "a quick run", "running
   on a track", "the sport of contests of speed".
2. **A meaning's words**: every word linked to the concept, per language. For the B1
   meaning: pt *carreira* B1, *vocação* B2, *profissão* B2, *ocupação* B2; en *career* B1,
   *calling* B1, *vocation* C1; it *vocazione* B2. A level belongs to the word in that
   meaning, so synonyms can differ.

Some lists are thin (it has only *vocazione* here) or empty (no it word for "running on a
track"), and some words are not drillable (multiword *esportes de corrida*, rare ones).

## Decisions (the user, 2026-11-15)

- One step from the card: its other meanings, and the other words for its meaning; no
  further jumps.
- A word page, opened by tapping a card in the round summary or a row in words to learn.
- All words WordNet links, each with its level, rare and multiword ones included.
- pt, en and it; an empty language is not shown.

## Current state

- The asset holds, per card, only the best meaning: one gloss and that concept's en and it
  words. No pt synonyms, no other meanings.
- Measured on the 0.9.0 corpus, read-only: the 19,467 cards have 43,386 word-meaning links
  (2.2 per word, at most 44), over 29,926 distinct meanings with 149,126 word entries in
  pt, en and it. With the en and pt glosses that is 10,683,724 bytes of JSON, 3,676,347
  gzipped; the card asset is 5,168,978.
- The lang-tools calls the export needs (`senses_for_lemma`, `lemmas_for_concept`,
  `get_concept_by_id`) are in its frozen surface.

## Approach

- A second asset, `meanings.json`, written by the export: the meanings each card links to
  (concept id, the word's level in it) and one table of meanings (en gloss, pt gloss when
  there is one, members per language with their levels). The card asset is unchanged, so
  the app's start stays as fast as now.
- The app reads `meanings.json` the first time a word page opens, in an isolate like the
  cards, and keeps it.
- The word page: the card's meaning first, with its other words in pt / en / it; then the
  word's other meanings, each with its gloss and its words, behind "Show all" when long.

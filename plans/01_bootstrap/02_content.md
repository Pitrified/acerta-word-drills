---
status: planned
---

# Phase 2 - Word content

## Overview

The words reach the app: a tool that writes the asset from the lang-tools corpus, the asset
itself, and the Dart side that loads it.
Context: [`00_start.md`](00_start.md), depends on [`01_skeleton.md`](01_skeleton.md).

## Goals

1. One committed asset holding every pt word the drill can use, reproducible by one command.
2. A Dart repository that answers "the cards at or under this level" from memory.
3. The data credit and the WordNet notice in the repo and ready for the about screen.

## Plan

- `tool/export_cards.py`: reads the corpus through `lang_tools.lexicon` (`CardQuery`,
  `lemma_cards`), with the web drill's filter (pt, known languages en and it, an English
  or an Italian translation, single word, 3 letters or more).
  Run with lang-tools' environment (`uv run --no-sync --project <lang-tools>`).
  A card query returns at most 500 cards and has no offset, and its translation filter wants
  every listed language at once. So the tool reads the corpus in slices, one level and one
  word length at a time, pages a slice larger than 500 by excluding the ids already read, and
  keeps the cards with an English or an Italian translation itself.
  The exclusion list stays short that way, far from SQLite's limit on query parameters.
- The asset: `assets/cards/pt_cards.json`, plain JSON with one card per line so a content
  update gives a readable diff; the APK compresses it.
  A header (asset format, lang-tools version, corpus build date, card count, the languages)
  and one record per card with only what the app shows or weights by:
  lemma id, text, part of speech, level, frequency, English gloss, up to four English and four
  Italian translations (the first is the pair, the rest are spares), look-alikes (language,
  text, kind, note). Sorted by frequency, then id.
- Measure the asset; if it is over about 5 MB compressed, cut the pool by level and say so in
  `00_start.md`.
- Dart: freezed models for the card and the look-alike, a `CardRepository` that loads the
  asset once at start and filters by level and by having a translation in the chosen
  language, a provider for it.
- Tests: the models parse a small fixture; the repository filters by level; a test that the
  real asset loads and its count matches its header.
- `docs/content.md`: what the asset holds, how to regenerate it, what a content update does to
  progress (ids are stable; a word that leaves the corpus leaves its progress behind).
- `DATA_LICENSE.md`: the credit text and the WordNet 3.0 notice, from lang-tools.

## Out of scope

- Example sentences, pt and Italian glosses.
- Any change in lang-tools.

## Done when

- The asset regenerates byte for byte from the same corpus.
- `scripts/check.sh` passes, with the asset test in it.
- The asset's size and count are recorded in `docs/content.md`.

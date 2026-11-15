---
status: done
---

# Phase 1 - Meanings asset

## Plan

- `tool/export_cards.py` also writes `assets/cards/pt_meanings.json`: a header like the
  cards' (format, corpus, counts); per card id, its meanings in sense order (best first)
  as `[concept key, the word's level]`; per concept key, the en gloss, the pt gloss when
  there is one, and `pt`, `en`, `it` lists of `[word, level]`, most frequent first.
- Same bytes for the same corpus; the size and counts go into `docs/content.md`.
- The file's shape is tested in Dart on the real asset, as the cards are (phase 2): the
  tool has no Python tests of its own.

## Done when

- The asset is written and reproducible; `scripts/check.sh` passes.

## What the implementation found

- `--meanings-out` writes it in the same run (17 s for both files). The lang-tools lookups
  return rows in no set order, so the export orders them: a card's meanings with its own
  first, then by frequency; a meaning's words by frequency, then text.
- Meanings are a list indexed from the cards rather than keyed by concept id, which brought
  the file from the estimated 10.7 MB to 8,116,552 bytes (2,476,860 gzipped); 29,926
  meanings over 43,386 links. Two runs give the same sha256.
- carreira: the B1 meaning lists pt carreira, profissão, ocupação, vocação; en calling,
  career, vocation; it vocazione; then the three B2 meanings.
- The card asset moved by one byte: its header names the lang-tools version, now
  `v0.9.0-2-gbf8a319` since the tags exist.

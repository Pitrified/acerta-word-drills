---
status: planned
---

# Phase 1 - Meanings asset

## Plan

- `tool/export_cards.py` also writes `assets/cards/pt_meanings.json`: a header like the
  cards' (format, corpus, counts); per card id, its meanings in sense order (best first)
  as `[concept key, the word's level]`; per concept key, the en gloss, the pt gloss when
  there is one, and `pt`, `en`, `it` lists of `[word, level]`, most frequent first.
- Same bytes for the same corpus; the size and counts go into `docs/content.md`.
- A test on a small fixture of the export's output shape, as the card export has.

## Done when

- The asset is written and reproducible; `scripts/check.sh` passes.

---
status: planned
---

# Phase 1 - The flag in the asset

## Overview

The data first: the export writes the flag and the app reads it, with no change in play yet.
Context: [`00_start.md`](00_start.md) (Q3).

## Plan

1. `tool/export_cards.py`: `_lookalike_record` writes `shares_meaning: true` when the hint has
   it; `FORMAT` 3 to 4 (Q3).
2. `Lookalike.sharesMeaning` (`@Default(false)`, JSON key `shares_meaning`), documented; codegen.
3. `supportedCardsFormat` 3 to 4.
4. Re-export from lang-tools `v0.12.0` (`assets/cards/pt_cards.json`, `pt_meanings.json`); the
   header names the tag.
5. `docs/content.md`: the field, the format, the measured counts (flagged look-alikes per
   language and kind).

## Tests

- `lookalike_test.dart`: `sharesMeaning` read, false when absent.
- `cards_asset_test.dart`: the real asset has flagged look-alikes, none on a cognate.

## Done when

- `scripts/check.sh` passes; the asset's flagged count matches lang-tools (293 edges, counted
  per card look-alike).

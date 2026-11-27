---
status: done
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

- `scripts/check.sh` passes; the asset's flagged look-alikes are lang-tools' 293 flagged pairs,
  less those whose pt card the export leaves out (counted and explained).

## What the implementation found

- Built by a Sonnet subagent at high effort from a one-line prompt pointing at this file (an
  audit-trial variation); accepted as is. `build.yaml`'s `field_rename: snake` maps
  `sharesMeaning` to `shares_meaning`, so no `@JsonKey` (which also trips a lint).
- The asset: 266 flagged look-alikes on 227 cards (131 en and 111 it `partial`, 14 en and 10 it
  `full`), none on a cognate. lang-tools flags 293 pairs; the other 27 are on 21 pt words whose
  card is an inflected form (*dados*, *era*, *preciso*), which the card query leaves out.
- The re-export changed only the flag on those 227 cards and the header (format 4, `v0.12.0`).
- `scripts/check.sh` passes with 320 tests.

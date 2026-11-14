---
status: done
---

# Phase 6 - Board layout

## Overview

The first look at the round on a screen ([`05_device_run.md`](05_device_run.md)) showed a
board that works and sits badly: small tiles in the top third, the feedback at the far
bottom edge. The user asked for it to be fixed before they try the app on the phone.
Context: [`00_start.md`](00_start.md).

## Goals

1. The tiles are easy to hit with a thumb: as wide as their column, taller, in the lower
   part of the screen.
2. The feedback is read without looking away from the board.

## Plan

- `WordTile`: fills the width of its column, larger text and padding.
- `_Board`: the feedback line and the two columns sit together at the bottom of the screen,
  feedback directly above the tiles, where a thumb on the tiles does not cover it.
  A longer note grows upwards, so the tiles never move.
  When the round is taller than the screen the whole of it scrolls.
- The board stays clear of the system navigation bar. On the emulator the round screen's
  body runs under the bar, which nothing showed while the board was at the top.
- Tests: the tiles of a column share one width; the feedback is above the first tile; the
  last tile is inside the safe area.
- `docs/drill.md`, "The round on screen", says where things are.
- A new APK from the commit, looked at on the emulator by screenshot.

## Out of scope

- The home screen's empty upper half, colours, animation: for the first use on the phone
  to judge.

## Done when

- `scripts/check.sh` and `scripts/e2e.sh` pass.
- A screenshot of the release build shows the board at the bottom, above the navigation
  bar, with the feedback above the tiles.

## What the implementation found

- The round screen's body did run under the navigation bar: with the safe area taken out,
  the layout test puts the last tile 40 px below the bar's top edge.
- The feedback went above the tiles rather than below them, where the hand would cover it.
- The screenshots of the release build on the emulator show five rows of full-width tiles
  ending just above the navigation bar, and "Wrong pair." directly above the first row.
- On a 320 x 568 phone a round of 8 pairs is taller than the screen and scrolls, as before.

# implementation tracking

A word page in acerta: a word's meanings, and the other words for the card's meaning in pt,
en and it. Analysis and decisions in [`00_start.md`](00_start.md).

## Key decisions

- One step from the card; opened from the summary and words to learn.
- All linked words with levels; pt, en, it.
- The meanings ship as a second asset, read on first use.

## Phases

| #  | Phase                  | Plan                                         | Status  |
| -- | ---------------------- | -------------------------------------------- | ------- |
| 1  | Meanings asset         | [`01_meanings_asset.md`](01_meanings_asset.md) | done |
| 2  | Word page              | [`02_word_page.md`](02_word_page.md)         | done |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-11-15 : bootstrapped after the user's carreira question; the two directions shown
  on real data; the four UI decisions answered; the size measured (10.7 MB JSON, 3.7 MB
  gzipped, against 5.2 MB for the cards), so the meanings get their own asset read on
  first use. Branch cut from `feat/01_bootstrap` (acerta has no `main` yet). Review: the
  export's lang-tools calls are in its frozen surface; a word with 44 meanings needs the
  long list collapsed; empty languages are hidden rather than shown empty.
- 2026-11-15 : the user said go. Phase 1 done: the export writes `pt_meanings.json`
  (8.1 MB, 2.5 MB gzipped, reproducible); `docs/content.md` describes it. The plan's
  Python test was wrong (the tool has none); the shape test moves to phase 2, in Dart.
- 2026-11-15 : phase 2, the code. A sonnet subagent wrote the meanings models and
  repository (loaded once, in an isolate, on the first word page), the providers, the
  `/word/:id` route, the word screen, the two entry points (the summary card's title and
  gloss, a words to learn row), 25 tests (a real-asset test included: every card has its
  own word in its first meaning, carreira lists profissão, ocupação, vocação), the e2e
  stage and the docs; four mutations caught. Review: no change. `scripts/check.sh` passes
  with 275 tests, `scripts/e2e.sh` passes.
- 2026-11-15 : phase 2 done; release APK `0.1.0+842a5878` looked at on the emulator (canal's
  page) and handed to the user. The page shows corpus noise the drill hid: plural pt
  members (canais, condutas) and a wrong one (cachimbo). Folder done.

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
| 1  | Meanings asset         | [`01_meanings_asset.md`](01_meanings_asset.md) | planned |
| 2  | Word page              | [`02_word_page.md`](02_word_page.md)         | planned |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-11-15 : bootstrapped after the user's carreira question; the two directions shown
  on real data; the four UI decisions answered; the size measured (10.7 MB JSON, 3.7 MB
  gzipped, against 5.2 MB for the cards), so the meanings get their own asset read on
  first use. Branch cut from `feat/01_bootstrap` (acerta has no `main` yet). Review: the
  export's lang-tools calls are in its frozen surface; a word with 44 meanings needs the
  long list collapsed; empty languages are hidden rather than shown empty.

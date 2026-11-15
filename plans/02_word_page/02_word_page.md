---
status: in progress
---

# Phase 2 - Word page

## Plan

- A meanings repository: loads `pt_meanings.json` in an isolate on first use, keeps it;
  a provider for one card's page data.
- Route `/word/:id`; the round summary card and the words to learn rows open it.
- The page: the word, its level and part of speech; "This meaning": the card's gloss, then
  "Also in Portuguese", "In English", "In Italian", each word with its level, the card's
  own word left out of pt; "Other meanings": each gloss with its words, the first few shown
  and "Show all" for the rest. A language with no word is not shown; a meaning with no
  other word says so.
- Loading state while the file is read; a missing card id shows "No details for this word".
- Tests on fakes: both sections, the hidden empty language, the collapsed list, the two
  entry points; e2e: open a word page from the summary.
- Docs: `docs/functional-specs.md`, `docs/content.md`.
- A new APK, looked at on the emulator with carreira or a word like it.

## Out of scope

- Tapping a word on the page (no further browsing).
- Drilling from the page.

## Done when

- `scripts/check.sh` and `scripts/e2e.sh` pass; the page looked at on the emulator.

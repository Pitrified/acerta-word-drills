---
status: done
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

## What the implementation found

- Release build `0.1.0+842a5878` on the emulator: the word page of canal (A2, "conduit ...")
  lists the en and pt glosses, "Also in Portuguese" with levels, "In English" tube B1,
  tubing C1, "In Italian" cannello C2, then the other meanings (B2 "long and narrow strip
  of water ..." with en canal, it canale, naviglio). The file loads in under the few
  seconds the tap took; the parse was 266 ms on the VM in the asset test.
- The APK grew by 2.5 MB, to 22.1 MB (arm64).
- Corpus content shows on the page that the drill never showed: the pt members of the
  conduit meaning include plurals stored as words of their own (canais, condutas) and a
  wrong member (cachimbo, a smoking pipe). These are lang-tools data, not page bugs.

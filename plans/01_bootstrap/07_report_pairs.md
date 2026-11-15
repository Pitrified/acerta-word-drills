---
status: in progress
---

# Phase 7 - Report a wrong pair

## Overview

The first round on the user's phone showed pairs the data gets wrong: "voluto - abandoned"
(C1), "estudo - work" with "work" before "study", "concitar - fire" at B1.
The fixes belong in lang-tools, as curated inputs; the app's job is to let the learner flag
a pair where they see it and get the flags off the phone.
The same round had six tiles on the right for five on the left: that is the decoy ("prove"
for "prover"), working as `docs/drill.md` says, and the user chose to keep it as it is.
Context: [`00_start.md`](00_start.md).

## Decisions

Functional, from the user:

- The report button is on the round summary only, next to "Don't show again".
- Reporting a pair also hides the word; it comes back from the hidden words list.
- The reports leave the phone as a file the learner saves on the phone.

Technical:

- The reports are their own Hive box, `reports`, keyed by card id, one report per word.
  They are not a flag on `WordProgress`: the progress reset keeps them, and a report
  carries what was on screen (the right word and the answer language), which progress has
  no place for.
- The file is written through Android's "create document" dialog (`ACTION_CREATE_DOCUMENT`),
  called over a method channel from `MainActivity`. It needs no storage permission and no
  new dependency, and the learner picks the folder.
- The file is JSON lines, one report per line, with what a lang-tools review needs to find
  the row: card id, Portuguese text, part of speech, level, gloss, the answer language, the
  right word shown and every translation in that language, the report time, and the app
  version.
- Saving does not clear the reports; the learner removes one from the list, or all of them
  with a confirmed button.

## Plan

- Model `WordReport` and `ReportRepository` (open, all, add, remove, clear), opened in
  `main` with the progress and settings boxes; `reportsProvider` with a notifier.
- Summary card: a "Report pair" button beside "Don't show again". It adds the report and
  hides the word; its label then reads "Reported, undo", which removes the report and shows
  the word again. A word hidden by hand is not reported.
- Settings: a "Reported pairs" row with the count, opening a screen that lists the reports
  (Portuguese - right word, language, date), each with Remove, and two buttons: "Save to
  file" and "Clear all" (confirmed).
- `ReportExport`: builds the JSON lines and hands them to the save channel; a fake in the
  widget tests. The file name is `acerta-reports-<yyyymmdd-hhmm>.jsonl`.
- Kotlin: `MainActivity` handles `saveText` on channel `acerta/save_file` with
  `ACTION_CREATE_DOCUMENT`, writes the text, and answers whether it was saved; a cancelled
  dialog is not an error.
- Tests: repository round trip on a real box; the summary button adds, hides and undoes;
  the reports screen lists, removes, clears, and saves through the fake; the JSON lines
  carry every field; the progress reset keeps the reports.
- e2e: one more stage reports a pair from the summary and checks it is listed and survives
  the restart. The file dialog itself is checked by hand on the emulator.
- Docs: `docs/functional-specs.md` and `docs/drill.md` (report and hide), the file format
  in `docs/content.md`, and `docs/privacy-policy.md` (the reports stay on the phone until
  the learner saves them to a file of their choosing).
- A new APK from the commit.

## Out of scope

- Reading the file in lang-tools: a review job there takes it as input, planned in
  lang-tools when the first file arrives.
- A reason or comment typed with the report.
- Reporting during the round.

## Done when

- `scripts/check.sh` and `scripts/e2e.sh` pass.
- On the emulator, with the release build: a pair reported from the summary is listed,
  saved to a file in Downloads, and the file holds one line per report.
- No new permission in the merged manifest.

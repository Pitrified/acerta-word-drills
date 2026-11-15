# implementation tracking

Bootstrap of acerta, an offline Android app for Portuguese pair matching drills on the
lang-tools lexicon, written fresh with fala-language-tutor and flutter-setup-project as
reference. Analysis and decisions in [`00_start.md`](00_start.md).

## Key decisions

- Offline: the words are a bundled asset, drills and progress live on the phone, no account,
  no network permission.
- The words come from the lang-tools corpus through a tool in this repo; lang-tools is not
  changed.
- Pair matching and word selection are rewritten in Dart from lang-tutor, same behaviour.
- Tooling, conventions and stack are fala's.

## Phases

| #  | Phase                    | Plan                                         | Status |
| -- | ------------------------ | -------------------------------------------- | ------ |
| 1  | Repo skeleton and gates  | [`01_skeleton.md`](01_skeleton.md)           | done |
| 2  | Word content             | [`02_content.md`](02_content.md)             | done |
| 3  | Pair matching            | [`03_pair_matching.md`](03_pair_matching.md) | done |
| 4  | Screens around the drill | [`04_screens.md`](04_screens.md)             | done |
| 5  | Device run               | [`05_device_run.md`](05_device_run.md)       | in progress |
| 6  | Board layout             | [`06_board_layout.md`](06_board_layout.md)   | done |
| 7  | Report a wrong pair      | [`07_report_pairs.md`](07_report_pairs.md)   | done |
| 8  | Words to learn           | [`08_learn_list.md`](08_learn_list.md)       | done |
| 9  | Topic picker             | [`09_topic_picker.md`](09_topic_picker.md)   | draft |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-11-14 : surveyed flutter-setup-project, fala-language-tutor and the lang-tutor and
  lang-tools servers with three read-only subagents; counted the pt pair matching words per
  level on the 2026-11-13 corpus; asked the four scoping questions (`00_start.md` Q1 to Q4);
  drafted the phases. Nothing outside this folder exists yet: no git repo, no code.
- 2026-11-14 : folded in `00_start.md` Q5 to Q10: level and round size are settings, the round
  ends on a summary with "don't show again", a small progress screen, and the right-hand side
  is English or Italian by a setting (the recommendation was English only). Counted the words
  with an Italian translation (1,805 up to B1, 19,240 in all). Q11 is open.
- 2026-11-14 : `00_start.md` Q11 answered (the phone only); the user validated the plan and
  asked for all five phases, a commit per phase on `feat/01_bootstrap`, pushes left to them.
  Review of phase 1 before starting: fala's tree carries no `gradlew` (Flutter writes it at
  build time), and its dependency set resolves against Flutter 3.44.5, so the lint plugins
  (`custom_lint`, `riverpod_lint`) are kept only if they resolve on 3.47.7. No other finding.
- 2026-11-14 : phase 1 done, commit `e248756` on `feat/01_bootstrap`. A sonnet subagent wrote
  the skeleton from fala's tree; the review of its diff changed three things: the instructions
  said the box has no emulator (it has one), the APK script got the JDK 17 fallback, and the
  build doc got the JDK line. `scripts/check.sh` passes in the tree and in a clean clone
  (`git clone --no-hardlinks`), where codegen took 32 s cold; `flutter build apk --debug`
  succeeds with JDK 17. The repo was initialised on `feat/01_bootstrap`, so `main` does not
  exist yet. Close review: no file outside `plans/` names fala except the two sibling-app
  lines in `README.md` and `docs/README.md`; the main manifest asks for no permission.
  Left for the user to check: the contact address in `docs/privacy-policy.md` (fala's), and
  its line saying the source is public at `Pitrified/acerta-word-drills`.
- 2026-11-14 : phase 2 started with its Python half, done while phase 1 ran:
  `tool/export_cards.py` and `assets/cards/pt_cards.json`, 29,376 cards, 7,023,975 bytes
  (2,022,112 with `gzip -9`, under the 5 MB bound, so every level ships). Two runs give the
  same sha256. Review before the Dart half: `02_content.md` said "one compressed JSON file"
  and planned a fallback to the store's drill table; the tool reads in level and length
  slices instead and needs neither, and the sub-plan now says so. 19,240 cards have an
  Italian translation, every card has an English one and a gloss, no id or text repeats.
  `DATA_LICENSE.md` written from lang-tools'.
- 2026-11-14 : phase 2 done. A sonnet subagent wrote the Dart half: `Level`,
  `AnswerLanguage`, `Lookalike`, `WordCard`, `CardsMeta`, `CardRepository` (parse, load in an
  isolate, pool by level and language, by id, count per level), its provider, and
  `docs/content.md`. It ran one mutation check per rule (level filter, language filter, format
  check), each seen failing. Review of its diff: the load path through the asset bundle and
  the isolate was untested, so a test with a fake bundle was added; nothing else changed.
  Close review: the asset regenerates byte for byte, the gates pass with the real-asset test
  in them, size and counts are in `docs/content.md`.
- 2026-11-14 : phase 3 started. Review before the code: the round needs the settings (level
  cap, pairs, answer language), which `04_screens.md` had planned to store, so the settings
  model, repository and provider moved into phase 3 and the screen stays in phase 4. The
  phase was split in two for the subagents: the logic (3a) and the round on screen (3b).
- 2026-11-14 : phase 3a. A sonnet subagent ported selection and pair matching from lang-tutor
  and wrote the progress and settings stores with their providers and `docs/drill.md`; it
  reported eleven mutations caught. Review: every source file read against lang-tutor's
  rules, no change needed; six mutations run again independently (uniform draw, error boost,
  decoy language, trap note for the same left word, shared translation, `resetCounts` keeps
  hidden), all six made a test fail, files restored.
- 2026-11-14 : phase 3 done. The same subagent setup wrote 3b (round state, `roundProvider`,
  the round screen and its tile, home with the start button, the `/round` route, Hive opened
  in `main`), was cut off by a usage limit part way and resumed with its context. Review of
  its diff changed three things: the feedback line had a fixed height that the longest trap
  note (102 characters) would overrun, now a minimum height; the fake progress store's reset
  dropped hidden words, unlike the real one; one tap rule in `docs/drill.md` reworded. Four
  mutations of the round provider run independently (error not recorded, finished too early,
  matched word not ignored, clock not read at the tap), all caught, file restored.
  `scripts/check.sh` passes with 106 tests. Close review: the "Done when" asked for a round
  on the emulator and progress after a restart, which nothing in this phase can prove; the
  sub-plan now says what was proven here (widget test of the whole app on fakes, Hive round
  trip in the repository test) and leaves the emulator proof to `05_device_run.md`.
- 2026-11-14 : phase 3 committed as `b8ee853`. Phase 4 started. Review before the code:
  `04_screens.md` still planned to store the settings (done in phase 3, corrected); the about
  screen's source link is plain selectable text, with no launcher dependency; the credit and
  the WordNet notice become Dart constants that a test compares with `DATA_LICENSE.md`.
  Pitfall noted: the progress and hidden-word lists look cards up by id, and an id that left
  the asset has to be skipped, not crash.
- 2026-11-14 : phase 4 done. A sonnet subagent wrote the round summary, settings, hidden
  words, progress and about screens, their providers, `lib/build_info.dart`,
  `lib/data_credit.dart` (held equal to `DATA_LICENSE.md` by a test), the two defines in
  `scripts/build-apk.sh` and `docs/functional-specs.md`; it reported seven mutations caught.
  Review of its diff changed two things: `CardRepository.poolSize` repeated the filter of
  `pool` and now returns its length, and the most missed line read "1 errors in 1 seen",
  now "missed 1 of 1". Seven other mutations run independently over the whole suite (the
  missed flag, the hidden flag of the summary, the seen count, the most missed limit,
  restore, a drift of the credit text, the pairs slider), all caught, files restored.
  `scripts/check.sh` passes with 171 tests. Close review: every screen is reached from home
  and back in `test/screens/navigation_test.dart`, a raised level cap brings a C1 word into
  the next round in `test/providers/round_level_cap_test.dart`. Nothing has been looked at
  on a screen yet: the layout tests only assert that nothing overflows at 320 x 568.
- 2026-11-14 : phase 4 committed as `f5b53c1`. Phase 5 started. Review before the code: the
  plan's "checks progress after a restart" cannot be two runs of `flutter test`, which
  removes the app after each; the restart is inside the one run (unmount, close the boxes,
  `main` again) and a real force-stop is checked by hand with the release APK, which is also
  the first look at the screens. `05_device_run.md` now says so.
- 2026-11-14 : phase 5, the run. `integration_test/app_test.dart` and `scripts/e2e.sh`
  written; the run passes on `fala_api36` (48 s after a 31 s build) and fails at the restart
  stage when the progress writes are kept out of the box, file restored. The release split
  build works (arm64 20.1 MB, debug-signed, no internet permission). By hand with the x86_64
  release APK: progress and the hidden word survive `am force-stop`; home, round, summary,
  progress, settings and about looked at by screenshot, findings in `05_device_run.md`.
  Docs: the emulator run in `docs/getting-started.md`, the structure, README and
  instructions. Close review: the phase stays `in progress`, because its last "Done when"
  line (the app on the user's phone, a round played) is the user's, and the spin-offs wait
  for `main` and for a number from the user.
- 2026-11-14 : phase 5 committed as `6da171c`. The release APKs were built again from that
  commit, so the about screen reads `0.1.0+6da171c4` (seen on the emulator, installed over
  the earlier build with its data kept), and the arm64 one was handed to the user.
  Waiting on the user: the install and a round on the phone, the keystore, the GitHub repo
  and `main`, the numbers for the spin-offs.
- 2026-11-14 : the user saw the screenshots and asked for the board layout to be fixed now:
  phase 6, `06_board_layout.md`. Review before the code: the screenshots show the round
  screen's body running under the navigation bar (the feedback box ends at the screen's
  bottom edge), so a board moved to the bottom needs the safe area, and the plan says so.
- 2026-11-14 : phase 6 done. Feedback and tiles sit at the bottom of the round screen inside
  the safe area, the tiles fill their column and are larger. One new layout test (equal
  widths, feedback above the tiles, last tile above the navigation bar); two mutations
  (no bottom safe area, tiles not stretched) each make it fail, file restored.
  `scripts/check.sh` passes with 173 tests and `scripts/e2e.sh` passes. Close review: the
  release build was looked at on the emulator before and after a wrong tap; a word too long
  for its tile still wraps inside it, as before.
- 2026-11-14 : phase 6 committed as `f92a7c8`. The release APKs were built again from that
  commit; the about screen reads `0.1.0+f92a7c83` and the board was looked at on the emulator
  in a fresh round and after a wrong tap. The arm64 one was handed to the user; it has the
  same debug signature as the earlier one, so it installs over it with the progress kept.
  Still waiting on the user for phase 5: the install and a round on the phone.
- 2026-11-15 : the user played on the phone and asked for two things: a button to report a
  wrong pair ("voluto - abandoned"), and why a round had six tiles on the right for five on
  the left. The sixth was the decoy "prove" for "prover", a full false friend in the asset,
  working as `docs/drill.md` says; the user chose to keep it as it is. For the report they
  chose: on the summary only, hiding the word too, out as a file saved on the phone. Phase 7,
  `07_report_pairs.md`. Review before the code: `MainActivity` is the bare Flutter one, so
  the save channel is its first native code; the summary reads the answer language from the
  round, which carries it; the privacy policy says the data stays on the phone, so it gets a
  line on the saved file, added to the plan. No other finding.
- 2026-11-15 : phase 7, the code. A sonnet subagent wrote `WordReport`, `ReportRepository`
  (Hive box `reports`), `reportsProvider`, the report button on the summary, the reported
  pairs screen, `ReportExport` and the save channel in `MainActivity`, the tests, the e2e
  stages and the docs; it reported four mutations caught (report without hiding, undo
  without showing, reset clearing the reports, a field dropped from the file). Review of its
  diff changed three things: the snackbar said "Saved 1 reports", now singular, with a test;
  the channel caught only an I/O error, and a provider refusing the write with a
  `SecurityException` would have crashed the app; the report time is stored in UTC.
  `scripts/check.sh` passes with 209 tests, `scripts/e2e.sh` passes (53 s).
- 2026-11-15 : phase 7 done. By hand on the emulator with the release build of `6676e6f`:
  a round played, two pairs reported from the summary (both hidden), listed on the reported
  pairs screen, saved through the Android dialog to Downloads; the pulled file holds one
  line per report. The file's `app_version` was the bare version name, now the version and
  commit label, with a test seen failing on the old value. Close review: the hand-hidden
  word that is then reported and undone comes back too, as the docs say for `undo`; a save
  pending when the activity is destroyed never answers, which leaves only the snackbar
  unshown. Phase 5 still waits on the user's phone.
- 2026-11-15 : the release APKs were built from `d69ce17`, label `0.1.0+d69ce175`. On the
  emulator it installed over the `6676e6f` build with the two reports kept, survived a
  force-stop, and a second save wrote a file whose lines carry `0.1.0+d69ce175`. The arm64
  APK was handed to the user.
- 2026-11-15 : the user asked for three more things: remove medical terms through a general
  topic picker, a button to mark words to learn, and the Italian translation on the summary.
  Measured on the asset: a hypernym rule (disease, symptom, drug, treatment, branches of
  medicine) catches 867 words, 853 of them C2; 25,310 of the 29,376 words are C2, 4,556 of
  them with no frequency. The user's answers: keep relatively common medical words
  ("cortisone or lung is ok, atelectasia is not"), the fix is in lang-tools, "we have too
  many C2 words"; topics as on/off chips with medical off; the mark is just a list; the
  summary title reads `estudo - work - studio`. Split agreed: lang-tools
  `20_rare_words_topics` (a commonness floor, the C2 band, a medical topic), acerta phase 8
  now (`08_learn_list.md`), the picker as phase 9 (`09_topic_picker.md`, draft) after
  lang-tools. Review of phase 8 before the code: the list reads cards by id like the hidden
  words screen, so a mark on an id that left the asset is skipped; no other finding.
- 2026-11-15 : phase 8, the code. A sonnet subagent wrote `LearnRepository` (Hive box
  `learn`), `learnProvider` and `learnWordsProvider`, the Learn this button, the summary
  title with the other language, the words to learn screen, the tests, the e2e stages and
  the docs, plus one privacy policy line on the marks (kept); it reported four mutations
  caught (title without the other language, mark not stored, reset clearing the marks,
  order reversed). Review of its diff: no change. `scripts/check.sh` passes with 232
  tests, `scripts/e2e.sh` passes (57 s).
- 2026-11-15 : phase 8 done, committed as `d073de6`; release APK `0.1.0+d073de6e` looked at
  on the emulator (summary titles with the Italian word, two words marked and listed) and
  handed to the user. lang-tools `20_rare_words_topics` drafted on `feat/20_rare_words_topics`
  with Q1 to Q3 answered: floor zipf 2.0, medical on by default and removing all medical
  words when off, and the CEFR bands re-cut (against the recommendation to keep them).
  Phase 9 (`09_topic_picker.md`) waits on it.

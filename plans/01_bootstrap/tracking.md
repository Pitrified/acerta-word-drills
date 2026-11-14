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
| 5  | Device run               | [`05_device_run.md`](05_device_run.md)       | planned |

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

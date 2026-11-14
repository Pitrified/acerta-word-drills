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
| 3  | Pair matching            | [`03_pair_matching.md`](03_pair_matching.md) | in progress |
| 4  | Screens around the drill | [`04_screens.md`](04_screens.md)             | planned |
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

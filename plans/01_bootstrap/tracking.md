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
| 1  | Repo skeleton and gates  | [`01_skeleton.md`](01_skeleton.md)           | in progress |
| 2  | Word content             | [`02_content.md`](02_content.md)             | planned |
| 3  | Pair matching            | [`03_pair_matching.md`](03_pair_matching.md) | planned |
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

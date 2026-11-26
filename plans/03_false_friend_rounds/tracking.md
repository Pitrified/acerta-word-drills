# implementation tracking

Rounds with fewer cognates and a false-friend decoy every time.
Analysis and decisions in [`00_start.md`](00_start.md).

## Key decisions

- A cognate card: the pt word looks like an en or it word of its own meaning, in any answer
  language, flagged once at load; cognate factor 0.1. False friends count in the answer
  language only.
  (Superseded by phase 4, the user on 2026-11-25: false friends count in either language.)
- Two slots per round: one full and one partial false friend in the answer language; the
  partial one from 5 pairs up. Small rounds are to be tuned separately, later.
- The asset stays at lang-tools `v0.10.1`.

## Phases

| #  | Phase                    | Plan                                                     | Status  |
| -- | ------------------------ | -------------------------------------------------------- | ------- |
| 1  | Cognate cards            | [`01_cognate_cards.md`](01_cognate_cards.md)             | done    |
| 2  | False-friend slots       | [`02_false_friend_slot.md`](02_false_friend_slot.md)     | done    |
| 3  | False friends in recap   | [`03_recap_false_friends.md`](03_recap_false_friends.md) | done    |
| 4  | Either-language false friends | [`04_cross_language_false_friends.md`](04_cross_language_false_friends.md) | in progress |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-11-23 : bootstrapped from the user's two asks; the shipped asset measured and a default
  round simulated (1.27 en / 1.90 it cognates per round, a decoy in 20% / 16% of rounds);
  the user chose the answer-language factors with cognate 0.3, a reserved full false-friend
  slot, and no re-export.
- 2026-11-23 : the user plays 8 pairs at C2 and sees more than one cognate a round; measured
  2.3 en / 2.9 it look-alike pairs per round, about 85% with no look-alike edge, which the
  lang-tools generator misses (filed as a lang-tools open point). Phase 1 gains a spelling
  check on the pair; phase 2 reserves two slots, a full and a partial false friend.
- 2026-11-23 : the user knows en and it both, so the cognate check compares the pt word with
  every en and it word of the card's meaning, whatever the answer language (*andar* "go" /
  *andare*); edges do not decide it. A false friend that is a word of the card's own meaning
  (*andar*'s `partial` *andare*) gets no boost and no slot.
- 2026-11-23 : review before execution (`00_start.md`, Review). Claims checked against the code
  hold. Measured: 56% of the asset's cards are cognate cards under the rule; with the two slots,
  4.3 cognate cards per 8-pair C2 round now, 2.4 at factor 0.3, 1.4 at 0.1. Sub-plans detailed
  with files and tests; the cognate flag moves to load time; decoys share the false-friend test;
  phase 1 file renamed. Three questions raised (Q1 where the flag lives, Q2 the factor, Q3 the
  slots in small rounds).
- 2026-11-23 : Q1 to Q3 folded in: the cognate flag at load (a), cognate factor 0.1 (b), the
  partial slot from 5 pairs up (b); the user: small rounds are a different game, tuned
  separately and not now.
- 2026-11-23 : phase 1 done on `feat/03_false_friend_rounds`: `lookalikes.dart` (similarity,
  cognate card, false friends in the answer language minus the card's own words), the cognate
  flag set by `CardRepository`, weights and decoys on the answer language, cognate factor 0.1,
  `docs/drill.md`. 1.02 en / 1.09 it cognate cards per 8 drawn at C2 (from 4.3). Four mutations
  caught; `scripts/check.sh` passes with 288 tests. Plan example corrected (*não* / *not*).
- 2026-11-23 : phase 2 code and tests: `drawRound` (full slot, partial slot from 5 pairs via
  `partialSlotMinPairs`, then the rest), wired into `RoundNotifier.start`; `docs/drill.md` "False-
  friend slots". Real asset, 1,000 8-pair C2 rounds per language: a decoy and a partial false friend
  in every round, 0 without a decoy in en and in it. Three mutations caught; `scripts/check.sh`
  passes with 296 tests. Left: `scripts/e2e.sh` (started, result not read), the release APK on
  the emulator, closing the phase. Nothing committed.
- 2026-11-23 : `scripts/e2e.sh` exit 1 before any test: the emulator did not boot (its log points
  at KVM acceleration). An environment problem, not a test result; the e2e run is still owed.
- 2026-11-24 : the 2026-11-23 boot failure was KVM access: logind gives `/dev/kvm` to the seat0
  session, and G7 was at the login screen (box note `~/repos/plans/2026-11-24_00_kvm_access_open_points.md`).
  With the desktop logged in, `scripts/e2e.sh` passes (1 test, 60 s). The teardown's
  `adb uninstall` printed `DELETE_FAILED_INTERNAL_ERROR` without failing the run.
  Left: the release APK on the emulator, closing the phase.
- 2026-11-24 : phase 2 done. Release APK (x86_64, from the uncommitted tree) on the emulator at
  C2, 8 pairs, English: 13 rounds started, each with a decoy on its first card. Cold start to the
  word count, coarse `uiautomator` polling: 3.19 to 3.25 s on this branch against 3.19 to 3.21 s
  for main (built from a `git archive` copy). Close review: the plan matches the code; no change.
  Folder done.
- 2026-11-25 : the user played the `0.1.0+843d9ddc` APK: many false friends, cognates fine,
  rounds harder, repeats accepted. Asked for a false-friends section in the round summary;
  added here as phase 3 (draft, `00_start.md` Q4 to Q7), the folder back to in progress.
- 2026-11-25 : the user reopened "false friends in the answer language only": an Italian false
  friend trips them in an English round too (pt *bravo* "angry", it *bravo* "good": show *good*
  as the trap). Added phase 4 (draft, `00_start.md` Q9 to Q13); Q4, Q6, Q7, Q8 folded into
  phase 3 (before the cards, cards unchanged, rows tappable, both languages listed); `Decoy`
  gets its look-alike in phase 3 so the recap can tell which one was on the board.
  Measured: `pt_meanings.json` gives other-language words for 664 of 728 full and partial
  look-alikes, some noisy (it *novella*: yarn, narration).
- 2026-11-25 : Q10 to Q13 answered: the decoy word of an other-language false friend comes from
  lang-tools, as the reviewed main sense of the look-alike word (`means` on the look-alike);
  first word not a right word or a translation of the card; the decoy picked at random between
  the answer-language and the other-language candidates; partial other-language ones allowed.
  Phase 4 rewritten around it; it waits on lang-tools `scratch_space/23_false_friend_meanings`
  (draft, branch `feat/23_false_friend_meanings`, created today).
- 2026-11-26 : lang-tools folder 23 released as `v0.11.0` (merged, tagged, pushed); phase 4 is
  unblocked. Review of phases 3 and 4 before execution (`00_start.md`, "Review of phases 3 and 4"):
  claims hold. Measured on a scratch dump of the `v0.11.0` cards: `means` gives an en word for all
  397 it false friends of en rounds and an it word for 328 of 397 en ones; the re-export also brings
  65 full false friends and 3,240 cognates from tier C. Sub-plans corrected (Current state, format 3,
  500-decoy read). Four questions raised: Q14 lead word only (reopens Q11), Q15 the slot pools,
  Q16 the tap message, Q17 the recap row.
- 2026-11-26 : Q14 to Q17 folded into phase 4: the lead `means` word only (Q11 superseded), the
  first slot from cards with a decoy candidate, the tap names the other-language look-alike, the
  recap row shows the lead word. The user asked whether the decoy is always the first card: it is,
  the reserved cards lead the pair order and the board shows the left column in that order;
  raised as Q18 (shuffle the pairs in `buildRound`, in phase 3).
- 2026-11-26 : Q18 folded into phase 3: `buildRound` shuffles the pairs once built, so the
  reserved cards leave the top of the board; tests and docs steps added.
- 2026-11-26 : add/remove pass on phases 3 and 4, the user's choices: phase 3 measures the recap
  rows per 8-pair C2 round on the real asset; phase 3's own APK hand-off cut, one after phase 4
  for both; the `on the board` label and phase 3's integration test kept. Not now: marking the
  tapped decoy, `means` on the word page. Parked in `plans/open_points.md` (new): the numbers
  below C1 (the user plays C1 and C2), and a pair report not naming the decoy (the card id and
  app version rebuild it for 92% of cards, which have one candidate). Phases 3 and 4 planned.
- 2026-11-26 : phase 3 done (`08508e5`). The summary's `False friends` section (`falseFriendEntries`,
  both languages, answer language and full first, `on the board` from the decoy's look-alike,
  rows open the word page); `Decoy` keeps its look-alike; `buildRound` shuffles the pairs, so the
  reserved cards leave the top of the board. Rows per 8-pair C2 round: 2.92 en, 3.05 it, at least 2.
  The new random stream surfaced a phase 2 gap (a partial slot card skipped when its only
  translation is taken, *negro* / *preto*); the real-asset test tolerates it as it does a lost decoy.
  Four mutations caught; check passes with 305 tests, e2e passes. Review at close: plan and code
  agree; no APK (one hand-off after phase 4).

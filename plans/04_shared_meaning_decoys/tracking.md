# implementation tracking

No false-friend decoy from a look-alike whose main meaning the pt word shares, from the flag
lang-tools `v0.12.0` puts on each look-alike, and a recap row that says the shared meaning.
Analysis and decisions in [`00_start.md`](00_start.md).

## Key decisions

- One rule: `decoyWordOf` gives no word for a flagged look-alike, so the draw, the decoys and
  the recap follow from it, for a flagged look-alike in either language (Q1).
- A flagged false friend stays in the recap, its row saying what it shares (Q2); the asset
  format goes to 4 (Q3); counts over 2,000 seeded rounds, no fresh read (Q4); an APK at the end
  (Q5).

## Phases

| #  | Phase                    | Plan                                       | Status |
| -- | ------------------------ | ------------------------------------------ | ------ |
| 1  | The flag in the asset    | [`01_asset_flag.md`](01_asset_flag.md)     | done |
| 2  | No shared decoys         | [`02_no_shared_decoys.md`](02_no_shared_decoys.md) | done |

Status values: draft / planned / in progress / done / superseded / discarded.

## Log

Append-only. Newest at the bottom.

- 2026-11-26 : picked up on branch `feat/04_shared_meaning_decoys` from `main`; 04 free on
  every ref. From the open point raised in `03_false_friend_rounds` Q19, after lang-tools
  `v0.12.0` (293 of 973 false-friend pairs flagged). Read `decoyWordOf`, `decoyCandidates`,
  the recap row and the export's look-alike record. Phases drafted; Q1 to Q5 raised.
- 2026-11-26 : Q1 to Q5 answered, all as recommended; folded in. Phases planned.
- 2026-11-26 : before, on the `v0.11.0` asset: decoy-slot pool 557 en / 394 it; decoys in 1,000
  en and 999 it of 1,000 seeded 8-pair C2 rounds, 638 and 620 from the other language.
- 2026-11-26 : phase 1 done (`b8d2878`). Export writes `shares_meaning`, `Lookalike.sharesMeaning`,
  format 4, re-exported from lang-tools `v0.12.0`: 266 flagged look-alikes on 227 cards (27 of
  lang-tools' 293 sit on inflected-form cards the asset leaves out). 320 tests pass.
- 2026-11-26 : phase 2 done, folder done (`b6efaa0`). `decoyWordOf` gives no word for a flagged
  look-alike; its recap row says `also`. After: decoy-slot pool 449 en / 330 it, a decoy in 999 en
  and 998 it rounds, 58% / 57% from the other language, none from a flagged look-alike; 166 of the
  661 read decoys drop out (84 of the 104 shared). e2e passes; APK on the emulator and sent.

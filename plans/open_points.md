# Open points

Known problems and ideas with no plan folder yet.
A point leaves this file when a folder picks it up.

## The false-friend numbers below C1

Raised 2026-11-26 in `03_false_friend_rounds`.
The rounds are tuned and measured at C1 and C2, the levels the user plays.
At lower levels the false-friend pools are much smaller (up to B1, about 56 en and 41 it cards
with a `full` look-alike in the `v0.10.1` asset), so the same decoys come back often.
To do: the decoy and recap measurements split by level, then a decision on whether low levels
need their own rules.

## A pair report does not name the decoy

Raised 2026-11-26 in `03_false_friend_rounds`.
A report of a pair stores the card id and the app version, which fix the card's decoy
candidates in that asset; 92% of the cards with a candidate have only one (515 of 557 en,
361 of 394 it, on the `v0.11.0` corpus), so the decoy can be rebuilt from the report.
It cannot say which candidate was on the board when there were two or more, or whether the
card's decoy was on the board at all.
To do, if the reports show bad decoys: a `decoy` field on `WordReport`.

## Decoys from a partial false friend that land on a shared meaning

Raised 2026-11-26 in `03_false_friend_rounds`.
A partial false friend in the other language gives as decoy the first word of what the look-alike
mainly means, and for 104 of the 290 such pairs that is a meaning the pt word also has (pt *tarde*
"afternoon" gets *late* from it *tardi*), so tapping it is not plainly wrong.
lang-tools reviews the partial pairs and flags those (its `scratch_space/24_partial_false_friend_meanings`).
To do once it ships: re-export, and have the export or the app give no decoy from a flagged pair.

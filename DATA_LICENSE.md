# Data license

The code in this repository is under the MIT license (`LICENSE`).
This file covers the word data the app ships: `assets/cards/pt_cards.json`.

## Where the data comes from

The asset is an export of the [lang-tools](https://github.com/Pitrified/lang-tools) lexicon,
written by `tool/export_cards.py` (see `docs/content.md`).
It holds Portuguese words with their level, an English gloss, English and Italian
translations and look-alike notes.
It holds no French data.

## License

The data is licensed under the
[Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/)
(CC BY 4.0), as lang-tools licenses it.
Copyright (c) 2026 Pietro Maria Nobili.

The full terms, the sources with their own licenses and the citations are in lang-tools'
[`DATA_LICENSE.md`](https://github.com/Pitrified/lang-tools/blob/main/DATA_LICENSE.md).

## Credit

The app shows this on its about screen, and a copy of the data carries it too:

> Lexical data from lang-tools by Pietro Maria Nobili, licensed under CC BY 4.0
> (https://github.com/Pitrified/lang-tools/blob/main/DATA_LICENSE.md).
> Built on Princeton WordNet 3.0, OpenWordnet-PT, the Multilingual Central Repository,
> MultiWordNet, the Collaborative Interlingual Index and wordfreq.

## Sources

| Source | Used for | License |
| --- | --- | --- |
| Princeton WordNet 3.0, as packaged in the Open Multilingual Wordnet 1.4 | English words, concepts and glosses | WordNet 3.0 license (below) |
| OpenWordnet-PT 1.0.0 | Portuguese words and their links to concepts | CC BY 4.0 |
| MultiWordNet, Italian | Italian words and their links to concepts | CC BY 3.0 |
| Collaborative Interlingual Index | the shared concept ids; English glosses where WordNet has none | CC BY 4.0 |
| wordfreq 3.1.1 | word frequencies, from which the levels are derived | data CC BY-SA 4.0, code Apache-2.0 |

The credit also names the Multilingual Central Repository (Spanish, CC BY 3.0):
it is the credit for the lang-tools corpus as a whole, and the asset holds no Spanish words.

The look-alike notes and the reviewed sense choices are text written for lang-tools and are
under the CC BY 4.0 license above.

## WordNet 3.0 license

This notice travels with every copy of the data; the app shows it on its licenses page.

```text
WordNet Release 3.0

This software and database is being provided to you, the LICENSEE, by
Princeton University under the following license.  By obtaining, using
and/or copying this software and database, you agree that you have
read, understood, and will comply with these terms and conditions.:

Permission to use, copy, modify and distribute this software and
database and its documentation for any purpose and without fee or
royalty is hereby granted, provided that you agree to comply with
the following copyright notice and statements, including the disclaimer,
and that the same appear on ALL copies of the software, database and
documentation, including modifications that you make for internal
use or for distribution.

WordNet 3.0 Copyright 2006 by Princeton University.  All rights reserved.

THIS SOFTWARE AND DATABASE IS PROVIDED "AS IS" AND PRINCETON
UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, PRINCETON
UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES OF MERCHANT-
ABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE
OF THE LICENSED SOFTWARE, DATABASE OR DOCUMENTATION WILL NOT
INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR
OTHER RIGHTS.

The name of Princeton University or Princeton may not be used in
advertising or publicity pertaining to distribution of the software
and/or database.  Title to copyright in this software, database and
any associated documentation shall at all times remain with
Princeton University and LICENSEE agrees to preserve same.
```

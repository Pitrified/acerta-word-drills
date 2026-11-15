# Content

## The asset

`assets/cards/pt_cards.json` holds every Portuguese single word of 3 letters or more in the lang-tools lexicon that has an English or an Italian translation and whose meaning is common enough: a frequency of at least 2.0 on the zipf scale.
The floor keeps out words a learner of this app should not meet, such as rare medical terms ("atelectasia" is 1.43).
It is one JSON object with a `meta` header and a `cards` list, one card per line, sorted most frequent first.

### Header

| Field | Meaning |
|-------|---------|
| `format` | Version of the asset layout, 2 |
| `language` | Language of the words, `pt` |
| `known_languages`, `translation_languages` | The languages the lexicon was queried with, `en` and `it` |
| `gloss_language` | Language of `gloss`, `en` |
| `lang_tools` | The lang-tools version the export ran against |
| `corpus_built_at` | When that corpus was built |
| `count` | Number of cards |

### Card

| Field | Meaning |
|-------|---------|
| `id` | Stable id of the word, the key of its progress |
| `text` | The Portuguese word |
| `pos` | `noun`, `adjective`, `verb` or `adverb` |
| `level` | CEFR level, `A1` to `C2` |
| `freq` | Frequency score, higher is more common; may be an integer in the JSON |
| `gloss` | English definition |
| `en`, `it` | Up to four translations, most frequent first; `en` is never empty, `it` is empty for about a third of the cards |
| `lookalikes` | Words in another language that look like this one |
| `topics` | The topics of the word, lowercase names such as `medical`; empty for a word with no topic, about a third of the cards |

The first entry of `en` or `it` is the one a round pairs with the word.
The others are spares for a round where two words share a translation.

A look-alike has a `language`, a `text`, a `note` and a `kind`:

- `full`: a false friend that never means the same; the note says what it means instead.
- `partial`: a false friend that shares an everyday meaning.
- `cognate`: an English or Italian word that descends from the same word and means the same.

## The reports file

The reported pairs leave the phone as a JSON lines file that the learner saves from the reported pairs screen: one JSON object per line, one line per report, UTF-8, named `acerta-reports-<yyyymmdd>-<hhmm>.jsonl`.
The keys are snake_case like the asset.

| Field | Meaning |
|-------|---------|
| `card_id` | The `id` of the card |
| `text`, `pos`, `level`, `gloss` | The card fields at the time of the report |
| `language` | The answer language of the round, `en` or `it` |
| `right` | The right word shown in the round |
| `translations` | Every translation of the card in `language`, most frequent first |
| `reported_at` | When the learner reported the pair, an ISO 8601 time |
| `app_version` | The version and commit of the app that wrote the file, such as `0.1.0+6676e6f6`; the commit fixes which export of the words the app carries. `dev+local` for a build without them |

The app writes the file through the Android dialog for a new file, so it needs no storage permission.
The dialog is a method channel, `acerta/save_file`, answered by `MainActivity`.

## Size

Measured on 2026-11-15, stable until the next export:

- 18,210 cards, 4,881,493 bytes, 1,328,357 bytes gzipped (`gzip -9`).
- Per level: A1 330, A2 516, B1 1,029, B2 2,664, C1 5,508, C2 8,163.
- 13,554 cards have an Italian translation, and all have an English one.
- 27 topics; `medical` is on 395 cards and 6,515 cards have no topic.

## Regenerating

From the repo root, with lang-tools checked out next to this repo and its corpus built:

```bash
SAMPLE_API_KEY=placeholder uv run --no-sync --project ../lang-tools python tool/export_cards.py --out assets/cards/pt_cards.json
```

`SAMPLE_API_KEY` is the one variable lang-tools requires, with any value.
`--no-sync` keeps uv from re-syncing the lang-tools environment.

The export is deterministic: the same corpus gives the same bytes, so `git diff --stat` after a run says whether the corpus changed.
The tool uses only the public card query of lang-tools (`CardQuery`, `lemma_cards`).
A query returns at most 500 cards and has no offset, so the tool reads one level and one word length at a time.

## What an update does to progress

Progress is keyed by the card `id`, which lang-tools keeps stable for a word.
A word that leaves the corpus leaves its progress record behind, unused.

The app refuses an asset whose `format` it does not know (`UnsupportedCardsFormatError`).
A layout change therefore bumps `FORMAT` in the tool and `supportedCardsFormat` in the app together.

## Loading

`CardRepository.load` reads the asset once at start and parses it in a background isolate, so the 5 MB parse stays off the UI isolate.
The repository holds the cards in memory and answers the pool for a level, an answer language and the topics that are off, and its size, a card by id, the count at exactly one level, and the number of cards of each topic.
`cardRepositoryProvider` exposes it.

## License

The words, glosses and look-alikes come from the lang-tools lexicon and are licensed as described in [DATA_LICENSE.md](../DATA_LICENSE.md).

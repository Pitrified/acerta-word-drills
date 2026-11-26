"""Write the app's word asset from the lang-tools corpus.

Every Portuguese word the pair matching drill can use is read through the
public card query of lang-tools (`CardQuery`, `lemma_cards`) and written as one
JSON file, one card per line, with a header naming the corpus it came from.
The output depends only on the corpus: the same corpus gives the same bytes.

Run it with lang-tools' environment, from this repo's root::

    uv run --no-sync --project ~/repos/lang-tools \
        python tool/export_cards.py --out assets/cards/pt_cards.json \
        --meanings-out assets/cards/pt_meanings.json

A card query returns at most `MAX_CARD_LIMIT` cards and has no offset, so the
corpus is read in slices (one CEFR band and one word length at a time), and a
slice larger than a page is paged by excluding the ids already read.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
from typing import Any

import lang_tools
from lang_tools.lexicon import CardQuery
from lang_tools.lexicon import LemmaCard
from lang_tools.lexicon import LookalikeHint
from lang_tools.lexicon import get_concept_by_id
from lang_tools.lexicon import get_lemma_by_id
from lang_tools.lexicon import lemma_cards
from lang_tools.lexicon import senses_for_concept
from lang_tools.lexicon import senses_for_lemma
from lang_tools.lexicon.card import MAX_CARD_LIMIT
from lang_tools.params.lang_tools_params import get_lang_tools_params

#: Version of the asset layout; the app refuses a file with another one.
#: 2 added `topics` to each card; 3 added `means` to a false friend's look-alike.
FORMAT = 3

LANGUAGE = "pt"
KNOWN_LANGUAGES = ["en", "it"]
TRANSLATION_LANGUAGES = ["en", "it"]
GLOSS_LANGUAGE = "en"
MIN_LENGTH = 3

#: Lowest frequency of a card's meaning (`sense_frequency`, zipf scale): rarer cards
#: are words a learner of this app should not meet (pt "atelectasia" is 1.43).
MIN_ZIPF = 2.0
BANDS = ["A1", "A2", "B1", "B2", "C1", "C2"]

#: Longest word length read as its own slice; longer words share one slice.
MAX_SLICE_LENGTH = 30

#: Version of the meanings asset layout; the app refuses a file with another one.
MEANINGS_FORMAT = 1

#: The languages a meaning lists its words in.
MEANING_LANGUAGES = ["pt", "en", "it"]

#: Translations kept per language: the first is the pair, the rest are spares
#: for a round where two words share their first translation.
MAX_TRANSLATIONS = 4


class NoCardsError(LookupError):
    """Raised when the corpus yields no card, which means it is not built."""

    def __init__(self) -> None:
        """Initialize with the fixed message."""
        super().__init__(
            "the lang-tools corpus returned no pt card; build it first "
            "(docs/guides/rebuild_corpus.md in lang-tools)",
        )


def _slice(band: str, **length: int) -> list[LemmaCard]:
    """Return every card of one band and length filter, paging by exclusion."""
    cards: list[LemmaCard] = []
    while True:
        page = lemma_cards(
            CardQuery(
                language=LANGUAGE,
                gloss_language=GLOSS_LANGUAGE,
                translation_languages=TRANSLATION_LANGUAGES,
                known_languages=KNOWN_LANGUAGES,
                single_word=True,
                min_zipf=MIN_ZIPF,
                min_cefr=band,
                max_cefr=band,
                order="frequency",
                limit=MAX_CARD_LIMIT,
                exclude_ids=[card.lemma.id for card in cards],
                **length,
            ),
        )
        cards.extend(page)
        if len(page) < MAX_CARD_LIMIT:
            return cards


def read_cards() -> list[LemmaCard]:
    """Return every pt card with an English or an Italian translation.

    Returns:
        The cards, most frequent first, ties by lemma id.

    Raises:
        NoCardsError: If the corpus yields nothing.
    """
    cards: list[LemmaCard] = []
    for band in BANDS:
        for length in range(MIN_LENGTH, MAX_SLICE_LENGTH + 1):
            cards.extend(_slice(band, length=length))
        cards.extend(_slice(band, min_length=MAX_SLICE_LENGTH + 1))
    cards = [card for card in cards if any(card.translations.values())]
    if not cards:
        raise NoCardsError
    cards.sort(key=lambda card: (-(card.sense_frequency or 0.0), card.lemma.id))
    return cards


def card_record(card: LemmaCard) -> dict[str, Any]:
    """Return the fields of a card the app shows or weights by."""
    record: dict[str, Any] = {
        "id": card.lemma.id,
        "text": card.lemma.text,
        "pos": card.lemma.part_of_speech,
        "level": card.cefr_level,
        "freq": round(card.sense_frequency or 0.0, 3),
        "gloss": card.gloss or "",
        "topics": card.topics,
    }
    for language in TRANSLATION_LANGUAGES:
        record[language] = card.translations.get(language, [])[:MAX_TRANSLATIONS]
    record["lookalikes"] = [_lookalike_record(hint) for hint in card.lookalikes]
    return record


def _lookalike_record(hint: LookalikeHint) -> dict[str, Any]:
    """Return a look-alike; `means` only when lang-tools gives it words."""
    record: dict[str, Any] = {
        "language": hint.language,
        "text": hint.text,
        "kind": hint.kind,
        "note": hint.note,
    }
    if hint.means:
        record["means"] = hint.means
    return record


def corpus_meta(count: int) -> dict[str, Any]:
    """Return the asset header: where the cards came from and how many."""
    params = get_lang_tools_params()
    build = json.loads((params.paths.data_fol / "lexicon" / "_build.json").read_text())
    described = subprocess.run(
        ["git", "describe", "--tags", "--always", "--dirty"],  # noqa: S607
        cwd=Path(lang_tools.__file__).parent,
        capture_output=True,
        text=True,
        check=True,
    )
    return {
        "format": FORMAT,
        "language": LANGUAGE,
        "known_languages": KNOWN_LANGUAGES,
        "translation_languages": TRANSLATION_LANGUAGES,
        "gloss_language": GLOSS_LANGUAGE,
        "lang_tools": described.stdout.strip(),
        "corpus_built_at": build["built_at"],
        "count": count,
    }


def render(cards: list[LemmaCard]) -> str:
    """Return the asset text: a JSON object with one card per line."""

    def dump(value: object) -> str:
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))

    lines = ",\n".join(dump(card_record(card)) for card in cards)
    return f'{{"meta":{dump(corpus_meta(len(cards)))},\n"cards":[\n{lines}\n]}}\n'


def _meaning(concept_id: str) -> dict[str, Any]:
    """Return one meaning: its glosses and its words per language, with levels.

    Words are listed most frequent first in the meaning (ties by text), after
    the reviewed lead of each language (`Sense.is_lead`), the word a card pairs;
    an inflected form is left out, as `lemmas_for_concept` does.
    """
    concept = get_concept_by_id(concept_id)
    definitions = concept.definitions if concept else {}
    record: dict[str, Any] = {"gloss": definitions.get(GLOSS_LANGUAGE, "")}
    if definitions.get(LANGUAGE):
        record["gloss_pt"] = definitions[LANGUAGE]
    words: dict[str, list[tuple[bool, float, str, str | None]]] = {}
    for sense in senses_for_concept(concept_id):
        if sense.form_note is not None:
            continue
        lemma = get_lemma_by_id(sense.lemma_id)
        if lemma is None or lemma.language not in MEANING_LANGUAGES:
            continue
        words.setdefault(lemma.language, []).append(
            (
                not sense.is_lead,
                -(sense.sense_frequency or 0.0),
                lemma.text,
                sense.cefr_level,
            ),
        )
    for language in MEANING_LANGUAGES:
        if words.get(language):
            record[language] = [
                [text, level] for _, _, text, level in sorted(set(words[language]))
            ]
    return record


def render_meanings(cards: list[LemmaCard]) -> tuple[str, int]:
    """Return the meanings asset text and how many meanings it holds.

    Each card lists its meanings as ``[index, level]`` into one shared list,
    the card's own meaning first, then the others most frequent first. The
    meanings are sorted by concept id, so the same corpus gives the same bytes.
    """
    links: dict[str, list[tuple[str, str | None]]] = {}
    concept_ids: set[str] = set()
    for card in cards:
        senses = sorted(
            senses_for_lemma(card.lemma.id),
            key=lambda s: (
                s.concept_id != card.concept_id,
                -(s.sense_frequency or 0.0),
                s.concept_id,
            ),
        )
        links[card.lemma.id] = [(s.concept_id, s.cefr_level) for s in senses]
        concept_ids.update(s.concept_id for s in senses)
    ordered = sorted(concept_ids)
    index = {concept_id: n for n, concept_id in enumerate(ordered)}

    def dump(value: object) -> str:
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))

    meta = {
        **{k: v for k, v in corpus_meta(len(cards)).items() if k != "format"},
        "format": MEANINGS_FORMAT,
        "meanings": len(ordered),
    }
    meanings = ",\n".join(dump(_meaning(concept_id)) for concept_id in ordered)
    card_links = ",\n".join(
        f"{dump(card_id)}:{dump([[index[c], level] for c, level in pairs])}"
        for card_id, pairs in links.items()
    )
    text = (
        f'{{"meta":{dump(meta)},\n"meanings":[\n{meanings}\n],\n'
        f'"cards":{{\n{card_links}\n}}}}\n'
    )
    return text, len(ordered)


def main(argv: list[str] | None = None) -> int:
    """Write the assets; return the exit code."""
    parser = argparse.ArgumentParser(prog="export_cards")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument(
        "--meanings-out",
        type=Path,
        help="also write each card's meanings and their words here",
    )
    args = parser.parse_args(argv)
    cards = read_cards()
    text = render(cards)
    args.out.write_text(text, encoding="utf-8")
    sys.stdout.write(
        f"{len(cards)} cards, {len(text.encode('utf-8'))} bytes -> {args.out}\n",
    )
    if args.meanings_out is not None:
        meanings, count = render_meanings(cards)
        args.meanings_out.write_text(meanings, encoding="utf-8")
        sys.stdout.write(
            f"{count} meanings, {len(meanings.encode('utf-8'))} bytes"
            f" -> {args.meanings_out}\n",
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())

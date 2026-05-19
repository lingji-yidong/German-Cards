#!/usr/bin/env python3
"""Download and convert a compact FreeDict German-English subset for GermanCards.

The full FreeDict deu-eng TEI source has 500k+ headwords. This script keeps the
app bundle small by extracting a curated high-frequency subset. Increase
COMMON_WORDS or replace it with your own list to grow the bundled reference.
"""

from __future__ import annotations

import argparse
import json
import lzma
import re
import tarfile
import urllib.request
from pathlib import Path
from xml.etree.ElementTree import iterparse

DOWNLOAD_URL = "https://download.freedict.org/dictionaries/deu-eng/1.9-fd1/freedict-deu-eng-1.9-fd1.src.tar.xz"
NS = "{http://www.tei-c.org/ns/1.0}"
COMMON_WORDS = {
    "Apfel", "Haus", "Zeit", "Buch", "Tisch", "Sprache", "Arbeit", "Wasser", "Mensch", "Frage", "Kind", "Tag",
    "Nacht", "Morgen", "Abend", "Woche", "Monat", "Jahr", "Name", "Stadt", "Land", "Weg", "Hand", "Auge", "Kopf",
    "Freund", "Familie", "Schule", "Universität", "Lehrer", "Schüler", "Student", "Essen", "Brot", "Milch", "Kaffee",
    "Tee", "Auto", "Zug", "Bahnhof", "Flughafen", "Zimmer", "Tür", "Fenster", "Straße", "Platz", "Liebe", "Leben",
    "Problem", "Antwort", "Beispiel", "Deutsch", "Wort", "Satz", "Grammatik", "Karte", "Computer", "Telefon",
    "Musik", "Film", "Bild", "Brief", "Geld", "Preis", "Markt", "Geschäft", "Berg", "Fluss", "Meer", "Baum", "Blume",
    "Sonne", "Regen", "Schnee", "Wind", "Licht", "Farbe", "Spiel", "Reise", "Urlaub", "Arzt", "Krankenhaus",
}


def text(element):
    return "".join(element.itertext()).strip() if element is not None else ""


def child_text(parent, path: str) -> str:
    return text(parent.find(path))


def direct_gram(entry, tag: str) -> str:
    gram = entry.find(NS + "gramGrp")
    return text(gram.find(NS + tag)) if gram is not None else ""


def clean_quote(value: str) -> str:
    value = re.sub(r"\s+", " ", value).strip()
    return re.sub(r"\s*\{[^}]+\}", "", value).strip()


def ensure_archive(path: Path) -> None:
    if path.exists() and path.stat().st_size > 1_000_000:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {DOWNLOAD_URL}")
    urllib.request.urlretrieve(DOWNLOAD_URL, path)


def convert(archive: Path, output: Path, limit_words: set[str]) -> None:
    entries = []
    seen = set()
    with lzma.open(archive) as compressed, tarfile.open(fileobj=compressed, mode="r|") as tar:
        for member in tar:
            if not member.name.endswith(".tei"):
                continue
            stream = tar.extractfile(member)
            if stream is None:
                continue
            for _, entry in iterparse(stream, events=("end",)):
                if entry.tag != NS + "entry":
                    continue
                word = child_text(entry, NS + "form/" + NS + "orth")
                if word in limit_words and word.lower() not in seen:
                    quotes = []
                    for cit in entry.findall(".//" + NS + "cit"):
                        if cit.attrib.get("type") != "trans":
                            continue
                        quote = clean_quote(child_text(cit, NS + "quote"))
                        if quote and quote not in quotes:
                            quotes.append(quote)
                        if len(quotes) >= 4:
                            break
                    if quotes:
                        entries.append({
                            "word": word,
                            "translations": quotes,
                            "partOfSpeech": direct_gram(entry, "pos") or "unknown",
                            "gender": direct_gram(entry, "gen"),
                            "source": "FreeDict deu-eng 1.9-fd1",
                        })
                        seen.add(word.lower())
                entry.clear()
                if len(seen) >= len(limit_words):
                    break
            break

    output.parent.mkdir(parents=True, exist_ok=True)
    entries.sort(key=lambda item: item["word"].lower())
    output.write_text(json.dumps({
        "source": "FreeDict German-English Ding/FreeDict dictionary 1.9-fd1",
        "license": "GPLv3/AGPLv3 mixed work; see FreeDict TEI header and https://freedict.org/downloads/",
        "downloadURL": DOWNLOAD_URL,
        "entryCount": len(entries),
        "entries": entries,
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(entries)} entries to {output}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", type=Path, default=Path(".cache/freedict-deu-eng.src.tar.xz"))
    parser.add_argument("--output", type=Path, default=Path("Resources/freedict_deu_eng_subset.json"))
    args = parser.parse_args()
    ensure_archive(args.archive)
    convert(args.archive, args.output, COMMON_WORDS)


if __name__ == "__main__":
    main()

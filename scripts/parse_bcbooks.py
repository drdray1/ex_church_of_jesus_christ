"""Converts bcbooks/scriptures-json volumes into volume JSON.

Source: https://github.com/bcbooks/scriptures-json, which is dedicated to the
public domain. It has the current (2013) edition's text without the Church's
copyrighted chapter summaries, footnotes or introductions. It does keep text
that is part of the scriptures, such as Psalm titles and the Book of Mormon's
original book and chapter headings.

Book ids, names, abbreviations, URL slugs and aliases come from
scripts/book_metadata.json.

    python scripts/parse_bcbooks.py --download <source dir>
    python scripts/parse_bcbooks.py <source dir> <out dir>
    for f in <out dir>/*.json; do python scripts/generate_volume.py "$f"; done

Keep <source dir> and <out dir> outside the repository.
"""
import json, os, sys, urllib.request

BASE = "https://raw.githubusercontent.com/bcbooks/scriptures-json/master/"
FILES = {
    "old_testament": "old-testament.json",
    "new_testament": "new-testament.json",
    "book_of_mormon": "book-of-mormon.json",
    "doctrine_and_covenants": "doctrine-and-covenants.json",
    "pearl_of_great_price": "pearl-of-great-price.json",
}
METADATA = os.path.join(os.path.dirname(__file__), "book_metadata.json")


def clean(text):
    return " ".join(text.split())


def verses(chapter):
    vs = chapter["verses"]
    assert [v["verse"] for v in vs] == list(range(1, len(vs) + 1)), chapter["reference"]
    return [clean(v["text"]) for v in vs]


def chapter(number, raw):
    out = {"number": number, "verses": verses(raw)}
    heading = raw.get("heading") or raw.get("note")
    if heading:
        out["heading"] = clean(heading)
    return out


def source_books(volume, src):
    """Yields (lds_slug, introduction paragraphs, chapters) for each book."""
    if volume == "doctrine_and_covenants":
        sections = src["sections"]
        assert [s["section"] for s in sections] == list(range(1, len(sections) + 1))
        yield "dc", [], [chapter(s["section"], s) for s in sections]
        return

    for book in src["books"]:
        chapters = [chapter(c["chapter"], c) for c in book["chapters"]]
        assert [c["number"] for c in chapters] == list(range(1, len(chapters) + 1)), book["book"]
        intro = [clean(book["heading"])] if book.get("heading") else []
        yield book["lds_slug"], intro, chapters


def front_matter(volume, src):
    if volume == "book_of_mormon":
        tp = src["title_page"]
        front = {"title_page": [tp["title"], tp["subtitle"], *tp["text"], tp["translated_by"]]}
        for t in src["testimonies"]:
            key = "testimony_of_" + t["title"].lower().removeprefix("testimony of ").replace(" ", "_")
            front[key] = [t["text"], *t["witnesses"]]
        return front
    if volume == "new_testament":
        tp = src["title_page"]
        return {"title_page": [tp["title"], tp["subtitle"], tp["text"]]}
    if volume == "doctrine_and_covenants":
        return {"title_page": [src["title"], src["subtitle"], src["subsubtitle"]]}
    if volume == "pearl_of_great_price":
        front = {"title_page": [src["title"], src["subtitle"]]}
        for book in src["books"]:
            for fac in book.get("facsimiles", []):
                front[f"facsimile_{fac['number']}"] = [fac["title"], *fac["explanations"]]
        return front
    return {}


def convert(meta, src):
    volume = meta["volume"]
    books = []
    for book_meta, (slug, intro, chapters) in zip(meta["books"], source_books(volume, src), strict=True):
        assert book_meta["url_slug"] == slug, (book_meta["url_slug"], slug)
        books.append({**book_meta, "introduction": intro, "chapters": chapters})
    return {
        "volume": {"id": volume, "module": meta["module"]},
        "front_matter": front_matter(volume, src),
        "books": books,
    }


def main(args):
    if args[0] == "--download":
        os.makedirs(args[1], exist_ok=True)
        for name in FILES.values():
            urllib.request.urlretrieve(BASE + name, os.path.join(args[1], name))
        return

    src_dir, out_dir = args
    os.makedirs(out_dir, exist_ok=True)
    for meta in json.load(open(METADATA, encoding="utf-8")):
        src = json.load(open(os.path.join(src_dir, FILES[meta["volume"]]), encoding="utf-8"))
        data = convert(meta, src)
        path = os.path.join(out_dir, meta["volume"] + ".json")
        json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        verses_total = sum(len(c["verses"]) for b in data["books"] for c in b["chapters"])
        print(f"{meta['volume']}: {len(data['books'])} books, {verses_total} verses -> {path}")


if __name__ == "__main__":
    main(sys.argv[1:])

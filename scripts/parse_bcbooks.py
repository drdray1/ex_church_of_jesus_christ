"""Converts a bcbooks/scriptures-json volume into volume JSON.

Source: https://github.com/bcbooks/scriptures-json (public domain; current
2013-edition text without the Church's copyrighted headings, footnotes or
introductions).

    curl -sL -o dc.json  https://raw.githubusercontent.com/bcbooks/scriptures-json/master/doctrine-and-covenants.json
    curl -sL -o pgp.json https://raw.githubusercontent.com/bcbooks/scriptures-json/master/pearl-of-great-price.json
    python scripts/parse_bcbooks.py doctrine_and_covenants dc.json dc-volume.json
    python scripts/parse_bcbooks.py pearl_of_great_price pgp.json pgp-volume.json
    python scripts/generate_volume.py dc-volume.json
    python scripts/generate_volume.py pgp-volume.json
"""
import json, sys

# id, module, name, abbreviation, aliases
DC_BOOK = ("doctrine_and_covenants", "DoctrineAndCovenants", "Doctrine and Covenants", "D&C",
           ["dc", "d and c", "doctrine & covenants", "doctrine and covenant"])

PGP_BOOKS = {
    "moses": ("moses", "Moses", "Moses", "Moses", ["book of moses"]),
    "abr": ("abraham", "Abraham", "Abraham", "Abr.", ["book of abraham", "abrah"]),
    "js-m": ("joseph_smith_matthew", "JosephSmithMatthew", "Joseph Smith—Matthew", "JS—M",
             ["jsm", "joseph smith matthew"]),
    "js-h": ("joseph_smith_history", "JosephSmithHistory", "Joseph Smith—History", "JS—H",
             ["joseph smith history"]),
    "a-of-f": ("articles_of_faith", "ArticlesOfFaith", "Articles of Faith", "A of F",
               ["aof", "aoff", "article of faith"]),
}


def verses(chapter):
    vs = chapter["verses"]
    assert [v["verse"] for v in vs] == list(range(1, len(vs) + 1)), chapter["reference"]
    return [v["text"].strip() for v in vs]


def doctrine_and_covenants(src):
    book_id, module, name, abbr, aliases = DC_BOOK
    sections = src["sections"]
    assert [s["section"] for s in sections] == list(range(1, 139))
    return {
        "volume": {"id": "doctrine_and_covenants", "module": "DoctrineAndCovenants"},
        "front_matter": {"title_page": [src["title"], src["subtitle"], src["subsubtitle"]]},
        "books": [{
            "id": book_id, "module": module, "name": name, "abbreviation": abbr,
            "url_slug": "dc", "title": src["title"], "subtitle": src["subsubtitle"],
            "introduction": [], "aliases": aliases,
            "chapters": [{"number": s["section"], "verses": verses(s)} for s in sections],
        }],
    }


def pearl_of_great_price(src):
    books, front = [], {"title_page": [src["title"], src["subtitle"]]}
    for b in src["books"]:
        book_id, module, name, abbr, aliases = PGP_BOOKS[b["lds_slug"]]
        books.append({
            "id": book_id, "module": module, "name": name, "abbreviation": abbr,
            "url_slug": b["lds_slug"], "title": b["full_title"], "subtitle": b.get("full_subtitle"),
            "introduction": [], "aliases": aliases,
            "chapters": [{"number": c["chapter"], "verses": verses(c)} for c in b["chapters"]],
        })
        for fac in b.get("facsimiles", []):
            front[f"facsimile_{fac['number']}"] = [fac["title"]] + fac["explanations"]
    return {"volume": {"id": "pearl_of_great_price", "module": "PearlOfGreatPrice"},
            "front_matter": front, "books": books}


if __name__ == "__main__":
    volume, src, out = sys.argv[1:4]
    data = {"doctrine_and_covenants": doctrine_and_covenants,
            "pearl_of_great_price": pearl_of_great_price}[volume](json.load(open(src, encoding="utf-8")))
    json.dump(data, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

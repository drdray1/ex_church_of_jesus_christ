"""Parses the New Testament of the Project Gutenberg King James Bible (eBook #10)
into volume JSON.

    curl -sL -o kjv.txt https://www.gutenberg.org/cache/epub/10/pg10.txt
    python scripts/parse_new_testament.py kjv.txt nt.json
    python scripts/generate_volume.py nt.json

The Gutenberg text prints each book as paragraphs in which verses start with a
"chapter:verse " marker, often several verses to a paragraph. Each book's text
is joined into one string and split on the markers, accepting only the marker
that must come next (the next verse, or verse 1 of the next chapter), so a
number that happens to look like a marker can never start a verse.
"""
import json, re, sys

src = sys.argv[1] if len(sys.argv) > 1 else "kjv.txt"
out = sys.argv[2] if len(sys.argv) > 2 else "nt.json"
lines = open(src, encoding="utf-8").read().replace("\r\n", "\n").split("\n")

nt_start = max(i for i, l in enumerate(lines) if l.strip() == "The New Testament of the King James Bible")
end = next(i for i, l in enumerate(lines) if l.startswith("*** END OF THE PROJECT"))

# (id, module, name, abbreviation, url_slug, Gutenberg heading, title, aliases)
BOOKS = [
    ("matthew", "Matthew", "Matthew", "Matt.", "matt", "The Gospel According to Saint Matthew",
     "The Gospel According to St Matthew", ["mt", "mat", "matt", "st matthew", "saint matthew"]),
    ("mark", "Mark", "Mark", "Mark", "mark", "The Gospel According to Saint Mark",
     "The Gospel According to St Mark", ["mk", "mr", "mrk", "st mark", "saint mark"]),
    ("luke", "Luke", "Luke", "Luke", "luke", "The Gospel According to Saint Luke",
     "The Gospel According to St Luke", ["lk", "luk", "st luke", "saint luke"]),
    ("john", "John", "John", "John", "john", "The Gospel According to Saint John",
     "The Gospel According to St John", ["jn", "jhn", "joh", "st john", "saint john"]),
    ("acts", "Acts", "Acts", "Acts", "acts", "The Acts of the Apostles",
     "The Acts of the Apostles", ["ac", "act", "acts of the apostles"]),
    ("romans", "Romans", "Romans", "Rom.", "rom", "The Epistle of Paul the Apostle to the Romans",
     "The Epistle of Paul the Apostle to the Romans", ["ro", "rm", "rom"]),
    ("first_corinthians", "FirstCorinthians", "1 Corinthians", "1 Cor.", "1-cor",
     "The First Epistle of Paul the Apostle to the Corinthians",
     "The First Epistle of Paul the Apostle to the Corinthians",
     ["1cor", "1 co", "1co", "1corinthians", "first corinthians", "i corinthians", "i cor"]),
    ("second_corinthians", "SecondCorinthians", "2 Corinthians", "2 Cor.", "2-cor",
     "The Second Epistle of Paul the Apostle to the Corinthians",
     "The Second Epistle of Paul the Apostle to the Corinthians",
     ["2cor", "2 co", "2co", "2corinthians", "second corinthians", "ii corinthians", "ii cor"]),
    ("galatians", "Galatians", "Galatians", "Gal.", "gal", "The Epistle of Paul the Apostle to the Galatians",
     "The Epistle of Paul the Apostle to the Galatians", ["ga"]),
    ("ephesians", "Ephesians", "Ephesians", "Eph.", "eph", "The Epistle of Paul the Apostle to the Ephesians",
     "The Epistle of Paul the Apostle to the Ephesians", ["ephes"]),
    ("philippians", "Philippians", "Philippians", "Philip.", "philip",
     "The Epistle of Paul the Apostle to the Philippians",
     "The Epistle of Paul the Apostle to the Philippians", ["phil", "php"]),
    ("colossians", "Colossians", "Colossians", "Col.", "col", "The Epistle of Paul the Apostle to the Colossians",
     "The Epistle of Paul the Apostle to the Colossians", ["colos"]),
    ("first_thessalonians", "FirstThessalonians", "1 Thessalonians", "1 Thes.", "1-thes",
     "The First Epistle of Paul the Apostle to the Thessalonians",
     "The First Epistle of Paul the Apostle to the Thessalonians",
     ["1 thess", "1thes", "1thess", "1 th", "1th", "1thessalonians", "first thessalonians",
      "i thessalonians", "i thes", "i thess"]),
    ("second_thessalonians", "SecondThessalonians", "2 Thessalonians", "2 Thes.", "2-thes",
     "The Second Epistle of Paul the Apostle to the Thessalonians",
     "The Second Epistle of Paul the Apostle to the Thessalonians",
     ["2 thess", "2thes", "2thess", "2 th", "2th", "2thessalonians", "second thessalonians",
      "ii thessalonians", "ii thes", "ii thess"]),
    ("first_timothy", "FirstTimothy", "1 Timothy", "1 Tim.", "1-tim",
     "The First Epistle of Paul the Apostle to Timothy",
     "The First Epistle of Paul the Apostle to Timothy",
     ["1tim", "1 ti", "1ti", "1timothy", "first timothy", "i timothy", "i tim"]),
    ("second_timothy", "SecondTimothy", "2 Timothy", "2 Tim.", "2-tim",
     "The Second Epistle of Paul the Apostle to Timothy",
     "The Second Epistle of Paul the Apostle to Timothy",
     ["2tim", "2 ti", "2ti", "2timothy", "second timothy", "ii timothy", "ii tim"]),
    ("titus", "Titus", "Titus", "Titus", "titus", "The Epistle of Paul the Apostle to Titus",
     "The Epistle of Paul the Apostle to Titus", ["tit"]),
    ("philemon", "Philemon", "Philemon", "Philem.", "philem", "The Epistle of Paul the Apostle to Philemon",
     "The Epistle of Paul the Apostle to Philemon", ["phm", "phlm", "philm"]),
    ("hebrews", "Hebrews", "Hebrews", "Heb.", "heb", "The Epistle of Paul the Apostle to the Hebrews",
     "The Epistle of Paul the Apostle to the Hebrews", ["hebr"]),
    ("james", "James", "James", "James", "james", "The General Epistle of James",
     "The General Epistle of James", ["jas", "jm", "jms"]),
    ("first_peter", "FirstPeter", "1 Peter", "1 Pet.", "1-pet", "The First Epistle General of Peter",
     "The First Epistle General of Peter",
     ["1pet", "1 pe", "1pe", "1 pt", "1pt", "1peter", "first peter", "i peter", "i pet"]),
    ("second_peter", "SecondPeter", "2 Peter", "2 Pet.", "2-pet", "The Second General Epistle of Peter",
     "The Second General Epistle of Peter",
     ["2pet", "2 pe", "2pe", "2 pt", "2pt", "2peter", "second peter", "ii peter", "ii pet"]),
    ("first_john", "FirstJohn", "1 John", "1 Jn.", "1-jn", "The First Epistle General of John",
     "The First Epistle General of John",
     ["1jn", "1 jhn", "1jhn", "1 jo", "1jo", "1john", "first john", "i john", "i jn"]),
    ("second_john", "SecondJohn", "2 John", "2 Jn.", "2-jn", "The Second Epistle General of John",
     "The Second Epistle General of John",
     ["2jn", "2 jhn", "2jhn", "2 jo", "2jo", "2john", "second john", "ii john", "ii jn"]),
    ("third_john", "ThirdJohn", "3 John", "3 Jn.", "3-jn", "The Third Epistle General of John",
     "The Third Epistle General of John",
     ["3jn", "3 jhn", "3jhn", "3 jo", "3jo", "3john", "third john", "iii john", "iii jn"]),
    ("jude", "Jude", "Jude", "Jude", "jude", "The General Epistle of Jude",
     "The General Epistle of Jude", ["jd"]),
    ("revelation", "Revelation", "Revelation", "Rev.", "rev", "The Revelation of Saint John the Divine",
     "The Revelation of St John the Divine",
     ["re", "rv", "revelations", "apocalypse", "the revelation", "revelation of john",
      "revelation of st john"]),
]


def normalize(name):
    # Mirrors ExChurchOfJesusChrist.Scriptures.Volume.normalize/1.
    name = re.sub(r"[\-–—_]", " ", name.lower().replace(".", ""))
    return re.sub(r"\s+", " ", name).strip()


# Every name must resolve to exactly one book within the volume.
owner = {}
for b in BOOKS:
    for n in [b[0], b[2], b[3]] + b[7]:
        prev = owner.setdefault(normalize(n), b[0])
        assert prev == b[0], f"{n!r} names both {prev} and {b[0]}"

body = lines[nt_start + 1:end]
starts, pos = [], 0
for b in BOOKS:
    i = next(j for j in range(pos, len(body)) if body[j].strip() == b[5])
    starts.append(i)
    pos = i + 1
starts.append(len(body))

marker_re = re.compile(r"(?<!\S)(\d+):(\d+)\s")

books, total_chapters, total_verses = [], 0, 0
for (bid, module, name, abbr, slug, _hdr, title, aliases), a, b in zip(BOOKS, starts, starts[1:]):
    text = " ".join(l.strip() for l in body[a + 1:b] if l.strip())
    text = re.sub(r"\s+", " ", text).strip()
    markers = list(marker_re.finditer(text))
    assert markers and markers[0].start() == 0 and markers[0].group(0) == "1:1 ", (name, text[:40])

    # Accept only the marker that must come next: (chapter, start, end) per verse.
    accepted, cur_c, cur_v = [], 0, 0
    for m in markers:
        c, v = int(m.group(1)), int(m.group(2))
        if (c == cur_c and v == cur_v + 1) or (c == cur_c + 1 and v == 1):
            accepted.append((c, m.start(), m.end()))
            cur_c, cur_v = c, v
        else:
            print(f"warning: ignoring out-of-sequence marker {c}:{v} in {name} (after {cur_c}:{cur_v})")

    chapters = []
    for i, (c, _s, e) in enumerate(accepted):
        stop = accepted[i + 1][1] if i + 1 < len(accepted) else len(text)
        if c > len(chapters):
            chapters.append({"number": c, "verses": []})
        chapters[c - 1]["verses"].append(text[e:stop].strip())

    for ch in chapters:
        for v in ch["verses"]:
            assert v and not re.search(r"\d+:\d+", v), (name, ch["number"], v)
    total_chapters += len(chapters)
    nv = sum(len(ch["verses"]) for ch in chapters)
    total_verses += nv
    print(f"{name}: {len(chapters)} chapters, {nv} verses")
    books.append({
        "id": bid, "module": module, "name": name, "abbreviation": abbr, "url_slug": slug,
        "title": title, "subtitle": None, "introduction": [], "aliases": aliases,
        "chapters": chapters,
    })

print(f"TOTAL: {len(books)} books, {total_chapters} chapters, {total_verses} verses")
json.dump({"volume": {"id": "new_testament", "module": "NewTestament"}, "books": books},
          open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

"""Parses the Old Testament from the Project Gutenberg King James Version
(eBook #10) into volume JSON.

    curl -sL -o kjv.txt https://www.gutenberg.org/cache/epub/10/pg10.txt
    python scripts/parse_old_testament.py kjv.txt ot.json
    python scripts/generate_volume.py ot.json

The Gutenberg text prints each verse as "C:V text", normally at the start of a
line, but some verses are run together on one line ("...one; 12:17 The king
of..."). The whole book is therefore scanned as one stream of text and split
on "C:V" markers, accepting a marker only when it is the next verse expected
(C:V+1 or C+1:1), so numbers that happen to appear in the text are never
mistaken for verses. Psalm superscriptions are not in the source (and are not
numbered verses in the KJV), so nothing is dropped from verse text.
"""
import json, re, sys

# (id, module, name, abbreviation, url_slug, title, aliases, chapters, verses)
# Chapter and verse counts are those of the KJV as published on
# churchofjesuschrist.org; the parser checks the source against them.
BOOKS = [
    ("genesis", "Genesis", "Genesis", "Gen.", "gen", "The First Book of Moses Called Genesis",
     ["gn", "ge"], 50, 1533),
    ("exodus", "Exodus", "Exodus", "Ex.", "ex", "The Second Book of Moses Called Exodus",
     ["exod", "exo", "exd"], 40, 1213),
    ("leviticus", "Leviticus", "Leviticus", "Lev.", "lev", "The Third Book of Moses Called Leviticus",
     ["lv", "le"], 27, 859),
    ("numbers", "Numbers", "Numbers", "Num.", "num", "The Fourth Book of Moses Called Numbers",
     ["nm", "nu", "numb"], 36, 1288),
    ("deuteronomy", "Deuteronomy", "Deuteronomy", "Deut.", "deut", "The Fifth Book of Moses Called Deuteronomy",
     ["dt", "deu"], 34, 959),
    ("joshua", "Joshua", "Joshua", "Josh.", "josh", "The Book of Joshua",
     ["jos", "jsh"], 24, 658),
    ("judges", "Judges", "Judges", "Judg.", "judg", "The Book of Judges",
     ["jdg", "jdgs", "jg"], 21, 618),
    ("ruth", "Ruth", "Ruth", "Ruth", "ruth", "The Book of Ruth",
     ["rth", "ru"], 4, 85),
    ("first_samuel", "FirstSamuel", "1 Samuel", "1 Sam.", "1-sam", "The First Book of Samuel",
     ["1sam", "1 sa", "1sa", "1 sm", "i samuel", "i sam", "1samuel"], 31, 810),
    ("second_samuel", "SecondSamuel", "2 Samuel", "2 Sam.", "2-sam", "The Second Book of Samuel",
     ["2sam", "2 sa", "2sa", "2 sm", "ii samuel", "ii sam", "2samuel"], 24, 695),
    ("first_kings", "FirstKings", "1 Kings", "1 Kgs.", "1-kgs", "The First Book of the Kings",
     ["1kgs", "1 kg", "1kg", "1 ki", "1ki", "1 kin", "i kings", "i kgs", "1kings"], 22, 816),
    ("second_kings", "SecondKings", "2 Kings", "2 Kgs.", "2-kgs", "The Second Book of the Kings",
     ["2kgs", "2 kg", "2kg", "2 ki", "2ki", "2 kin", "ii kings", "ii kgs", "2kings"], 25, 719),
    ("first_chronicles", "FirstChronicles", "1 Chronicles", "1 Chr.", "1-chr", "The First Book of the Chronicles",
     ["1chr", "1 chron", "1chron", "1 ch", "1ch", "i chronicles", "i chr", "1chronicles"], 29, 942),
    ("second_chronicles", "SecondChronicles", "2 Chronicles", "2 Chr.", "2-chr", "The Second Book of the Chronicles",
     ["2chr", "2 chron", "2chron", "2 ch", "2ch", "ii chronicles", "ii chr", "2chronicles"], 36, 822),
    ("ezra", "Ezra", "Ezra", "Ezra", "ezra", "Ezra",
     ["ezr"], 10, 280),
    ("nehemiah", "Nehemiah", "Nehemiah", "Neh.", "neh", "The Book of Nehemiah",
     ["nehem"], 13, 406),
    ("esther", "Esther", "Esther", "Esth.", "esth", "The Book of Esther",
     ["est", "es"], 10, 167),
    ("job", "Job", "Job", "Job", "job", "The Book of Job",
     ["jb"], 42, 1070),
    ("psalms", "Psalms", "Psalms", "Ps.", "ps", "The Book of Psalms",
     ["psalm", "psa", "psm", "pss", "pslm"], 150, 2461),
    ("proverbs", "Proverbs", "Proverbs", "Prov.", "prov", "The Proverbs",
     ["pro", "prv", "pr"], 31, 915),
    ("ecclesiastes", "Ecclesiastes", "Ecclesiastes", "Eccl.", "eccl", "Ecclesiastes or, the Preacher",
     ["ecc", "eccles", "ec", "qoheleth"], 12, 222),
    ("song_of_solomon", "SongOfSolomon", "Song of Solomon", "Song", "song", "The Song of Solomon",
     ["song of songs", "sos", "so", "canticles", "canticle of canticles", "cant"], 8, 117),
    ("isaiah", "Isaiah", "Isaiah", "Isa.", "isa", "The Book of the Prophet Isaiah",
     ["is"], 66, 1292),
    ("jeremiah", "Jeremiah", "Jeremiah", "Jer.", "jer", "The Book of the Prophet Jeremiah",
     ["je", "jr"], 52, 1364),
    ("lamentations", "Lamentations", "Lamentations", "Lam.", "lam", "The Lamentations of Jeremiah",
     ["la"], 5, 154),
    ("ezekiel", "Ezekiel", "Ezekiel", "Ezek.", "ezek", "The Book of the Prophet Ezekiel",
     ["eze", "ezk"], 48, 1273),
    ("daniel", "Daniel", "Daniel", "Dan.", "dan", "The Book of Daniel",
     ["da", "dn"], 12, 357),
    ("hosea", "Hosea", "Hosea", "Hosea", "hosea", "Hosea",
     ["hos", "ho"], 14, 197),
    ("joel", "Joel", "Joel", "Joel", "joel", "Joel",
     ["jl"], 3, 73),
    ("amos", "Amos", "Amos", "Amos", "amos", "Amos",
     ["am"], 9, 146),
    ("obadiah", "Obadiah", "Obadiah", "Obad.", "obad", "Obadiah",
     ["ob", "oba", "obd"], 1, 21),
    ("jonah", "Jonah", "Jonah", "Jonah", "jonah", "Jonah",
     ["jon", "jnh"], 4, 48),
    ("micah", "Micah", "Micah", "Micah", "micah", "Micah",
     ["mic", "mc"], 7, 105),
    ("nahum", "Nahum", "Nahum", "Nahum", "nahum", "Nahum",
     ["nah", "na"], 3, 47),
    ("habakkuk", "Habakkuk", "Habakkuk", "Hab.", "hab", "Habakkuk",
     ["habak"], 3, 56),
    ("zephaniah", "Zephaniah", "Zephaniah", "Zeph.", "zeph", "Zephaniah",
     ["zep", "zp"], 3, 53),
    ("haggai", "Haggai", "Haggai", "Hag.", "hag", "Haggai",
     ["hg"], 2, 38),
    ("zechariah", "Zechariah", "Zechariah", "Zech.", "zech", "Zechariah",
     ["zec", "zc"], 14, 211),
    ("malachi", "Malachi", "Malachi", "Mal.", "mal", "Malachi",
     ["ml"], 4, 55),
]

# Book headings in the Gutenberg text, in order (the body repeats the table
# of contents at the top of the file).
HEADINGS = [
    "The First Book of Moses: Called Genesis", "The Second Book of Moses: Called Exodus",
    "The Third Book of Moses: Called Leviticus", "The Fourth Book of Moses: Called Numbers",
    "The Fifth Book of Moses: Called Deuteronomy", "The Book of Joshua", "The Book of Judges",
    "The Book of Ruth", "The First Book of Samuel", "The Second Book of Samuel",
    "The First Book of the Kings", "The Second Book of the Kings",
    "The First Book of the Chronicles", "The Second Book of the Chronicles", "Ezra",
    "The Book of Nehemiah", "The Book of Esther", "The Book of Job", "The Book of Psalms",
    "The Proverbs", "Ecclesiastes", "The Song of Solomon", "The Book of the Prophet Isaiah",
    "The Book of the Prophet Jeremiah", "The Lamentations of Jeremiah",
    "The Book of the Prophet Ezekiel", "The Book of Daniel", "Hosea", "Joel", "Amos",
    "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah",
    "Malachi",
]
END = "The New Testament of the King James Bible"

MARKER = re.compile(r"(?<![\d:])(\d+):(\d+)\s+")


def parse_book(text):
    """Splits a book's text into chapters of verses on sequential C:V markers."""
    chapters, pos, starts = [], 0, []
    expected = [(1, 1)]
    for m in MARKER.finditer(text):
        c, v = int(m.group(1)), int(m.group(2))
        if (c, v) not in expected:
            continue
        starts.append((c, v, m.start(), m.end()))
        expected = [(c, v + 1), (c + 1, 1)]
    for i, (c, v, _, body) in enumerate(starts):
        end = starts[i + 1][2] if i + 1 < len(starts) else len(text)
        verse = " ".join(text[body:end].split())
        if c > len(chapters):
            chapters.append({"number": c, "verses": []})
        chapters[-1]["verses"].append(verse)
    return chapters


def main(src, out):
    lines = open(src, encoding="utf-8").read().split("\n")
    lines = [l.rstrip() for l in lines]
    # Skip the table of contents: start at the second "Old Testament" title.
    start = [i for i, l in enumerate(lines) if l == "The Old Testament of the King James Version of the Bible"][1]
    # The Old Testament ends at a "***" separator before the New Testament.
    end = next(i for i in range(start, len(lines)) if lines[i] in (END, "***"))
    body = lines[start + 1:end]

    idx, pos = [], 0
    for h in HEADINGS:
        i = next(j for j in range(pos, len(body)) if body[j] == h)
        idx.append(i)
        pos = i + 1
    idx.append(len(body))

    books, total_c, total_v, ok = [], 0, 0, True
    for meta, a, b in zip(BOOKS, idx, idx[1:]):
        bid, module, name, abbr, slug, title, aliases, n_ch, n_v = meta
        chapters = parse_book("\n".join(body[a + 1:b]))
        verses = sum(len(c["verses"]) for c in chapters)
        for c in chapters:
            for v in c["verses"]:
                assert v and v == v.strip(), (name, c["number"], v)
                assert not re.search(r"\d+:\d+", v), (name, c["number"], v)
        status = "" if (len(chapters), verses) == (n_ch, n_v) else f"  MISMATCH expected {n_ch}/{n_v}"
        ok = ok and not status
        print(f"{name:18} {len(chapters):4} {verses:5}{status}")
        total_c += len(chapters)
        total_v += verses
        books.append({
            "id": bid, "module": module, "name": name, "abbreviation": abbr, "url_slug": slug,
            "title": title, "subtitle": None, "introduction": [], "aliases": aliases,
            "chapters": chapters,
        })
    print(f"TOTAL {len(books)} books, {total_c} chapters, {total_v} verses")
    assert ok and (len(books), total_c, total_v) == (39, 929, 23145)

    json.dump({"volume": {"id": "old_testament", "module": "OldTestament"}, "books": books},
              open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "kjv.txt", sys.argv[2] if len(sys.argv) > 2 else "ot.json")

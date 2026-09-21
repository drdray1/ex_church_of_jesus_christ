"""Parses the Project Gutenberg Book of Mormon (eBook #17) into volume JSON.

    curl -sL -o bom.txt https://www.gutenberg.org/cache/epub/17/pg17.txt
    python scripts/parse_book_of_mormon.py bom.txt bom.json
    python scripts/generate_volume.py bom.json
"""
import re, json, sys
lines = open(sys.argv[1] if len(sys.argv) > 1 else "bom.txt", encoding="utf-8").read().split("\n")
start = next(i for i,l in enumerate(lines) if l.startswith("THE FIRST BOOK OF NEPHI HIS REIGN"))
end = next(i for i,l in enumerate(lines) if l.startswith("*** END OF THE PROJECT"))

def paras(block):
    out, cur = [], []
    for l in block:
        s = l.strip()
        if s: cur.append(s)
        elif cur: out.append(" ".join(cur)); cur = []
    if cur: out.append(" ".join(cur))
    return out

def witness_paras(block):
    out, cur = [], []
    for l in block + [""]:
        s = l.strip()
        if s and s.upper() == s:
            if cur: out.append(" ".join(cur)); cur = []
            out.append(s)
        elif s: cur.append(s)
        elif cur: out.append(" ".join(cur)); cur = []
    return out

# front matter
fm = lines[:start]
ti = next(i for i,l in enumerate(fm) if l.strip()=="THE BOOK OF MORMON")
t3 = next(i for i,l in enumerate(fm) if l.strip()=="THE TESTIMONY OF THREE WITNESSES")
t8 = next(i for i,l in enumerate(fm) if l.strip()=="THE TESTIMONY OF EIGHT WITNESSES")
tc = next(i for i,l in enumerate(fm) if l.strip()=="Contents")
front = {
  "title_page": paras(fm[ti:t3]),
  "three_witnesses": witness_paras(fm[t3+1:t8]),
  "eight_witnesses": witness_paras(fm[t8+1:tc]),
}

BOOKS = [
 ("1 Nephi","first_nephi","THE FIRST BOOK OF NEPHI HIS REIGN AND MINISTRY (1 Nephi)"),
 ("2 Nephi","second_nephi","THE SECOND BOOK OF NEPHI"),
 ("Jacob","jacob","THE BOOK OF JACOB"),
 ("Enos","enos","THE BOOK OF ENOS"),
 ("Jarom","jarom","THE BOOK OF JAROM"),
 ("Omni","omni","THE BOOK OF OMNI"),
 ("Words of Mormon","words_of_mormon","THE WORDS OF MORMON"),
 ("Mosiah","mosiah","THE BOOK OF MOSIAH"),
 ("Alma","alma","THE BOOK OF ALMA"),
 ("Helaman","helaman","THE BOOK OF HELAMAN"),
 ("3 Nephi","third_nephi","THIRD BOOK OF NEPHI"),
 ("4 Nephi","fourth_nephi","FOURTH NEPHI"),
 ("Mormon","mormon","THE BOOK OF MORMON"),
 ("Ether","ether","THE BOOK OF ETHER"),
 ("Moroni","moroni","THE BOOK OF MORONI"),
]
body = lines[start:end]
idx = []
pos = 0
for name, slug, hdr in BOOKS:
    i = next(j for j in range(pos, len(body)) if body[j].strip()==hdr)
    idx.append(i); pos = i+1
idx.append(len(body))

verse_re = re.compile(r"^(?:[1-4]?\s?[A-Z][a-z]+(?: of [A-Z][a-z]+)? )?(\d+):(\d+) (.*)$")
chap_re = re.compile(r"^(.+) Chapter (\d+)$")
books = []
for (name, slug, hdr), a, b in zip(BOOKS, idx, idx[1:]):
    blk = body[a+1:b]
    # title continuation lines (all caps) right after header
    title = [hdr.replace(" (1 Nephi)","")]
    k = 0
    while k < len(blk) and (not blk[k].strip() or blk[k].strip().upper()==blk[k].strip() and not verse_re.match(blk[k].strip())):
        if blk[k].strip(): title.append(blk[k].strip())
        k += 1
    chapters, intro, pre, cur, curv = [], [], [], None, None
    def flush():
        global curv
        if curv is None: return
        v = curv
        while True:
            marker = f" {cur['number']}:{v['number']+1} "
            p = v["text"].find(marker)
            if p < 0: break
            nxt = {"number": v["number"]+1, "text": v["text"][p+len(marker):]}
            v["text"] = v["text"][:p]
            cur["verses"].append(v); v = nxt
        cur["verses"].append(v); curv = None
    buf = []
    for l in blk[k:]:
        s = l.strip()
        m = chap_re.match(s)
        if m:
            flush()
            cur = {"number": int(m.group(2)), "heading": [], "verses": []}
            chapters.append(cur); continue
        m = verse_re.match(s) if s else None
        if m:
            flush()
            if cur is None:
                cur = {"number": 1, "heading": [], "verses": []}; chapters.append(cur)
            c, v = int(m.group(1)), int(m.group(2))
            assert c == cur["number"], (name, c, v, cur["number"])
            assert v == len(cur["verses"])+1, (name, c, v)
            curv = {"number": v, "text": m.group(3)}
            continue
        if curv is not None:
            if s: curv["text"] += " " + s
            else: flush()
        else:
            (intro if cur is None else cur["heading"]).append(l)
    flush()
    for c in chapters:
        c["heading"] = paras(c["heading"])
    books.append({"name": name, "slug": slug, "title": " ".join(t.title() if False else t for t in title),
                  "introduction": paras(intro), "chapters": chapters})

total = sum(len(c["verses"]) for bk in books for c in bk["chapters"])
for bk in books:
    print(bk["name"], len(bk["chapters"]), sum(len(c["verses"]) for c in bk["chapters"]), "| title:", bk["title"], "| intro paras:", len(bk["introduction"]),
          "| chapter headings:", sum(1 for c in bk["chapters"] if c["heading"]))
print("TOTAL", total)
META = {
 "first_nephi":     ("FirstNephi", "1 Ne.", "1-ne", "The First Book of Nephi", "His Reign and Ministry", ["1 nephi", "1 ne", "1ne", "1nephi", "first nephi", "i nephi"]),
 "second_nephi":    ("SecondNephi", "2 Ne.", "2-ne", "The Second Book of Nephi", None, ["2 nephi", "2 ne", "2ne", "2nephi", "second nephi", "ii nephi"]),
 "jacob":           ("Jacob", "Jacob", "jacob", "The Book of Jacob", "The Brother of Nephi", ["jac"]),
 "enos":            ("Enos", "Enos", "enos", "The Book of Enos", None, []),
 "jarom":           ("Jarom", "Jarom", "jarom", "The Book of Jarom", None, ["jar"]),
 "omni":            ("Omni", "Omni", "omni", "The Book of Omni", None, []),
 "words_of_mormon": ("WordsOfMormon", "W of M", "w-of-m", "The Words of Mormon", None, ["wofm", "wom"]),
 "mosiah":          ("Mosiah", "Mosiah", "mosiah", "The Book of Mosiah", None, ["mos"]),
 "alma":            ("Alma", "Alma", "alma", "The Book of Alma", "The Son of Alma", []),
 "helaman":         ("Helaman", "Hel.", "hel", "The Book of Helaman", None, []),
 "third_nephi":     ("ThirdNephi", "3 Ne.", "3-ne", "Third Nephi", "The Book of Nephi, the Son of Nephi, Who Was the Son of Helaman", ["3 nephi", "3 ne", "3ne", "3nephi", "third nephi", "iii nephi"]),
 "fourth_nephi":    ("FourthNephi", "4 Ne.", "4-ne", "Fourth Nephi", "The Book of Nephi, Who Is the Son of Nephi—One of the Disciples of Jesus Christ", ["4 nephi", "4 ne", "4ne", "4nephi", "fourth nephi", "iv nephi"]),
 "mormon":          ("Mormon", "Morm.", "morm", "The Book of Mormon", None, []),
 "ether":           ("Ether", "Ether", "ether", "The Book of Ether", None, ["eth"]),
 "moroni":          ("Moroni", "Moro.", "moro", "The Book of Moroni", None, ["mni"]),
}

volume_books = []
for bk in books:
    module, abbr, url, title, subtitle, aliases = META[bk["slug"]]
    volume_books.append({
        "id": bk["slug"], "module": module, "name": bk["name"], "abbreviation": abbr,
        "url_slug": url, "title": title, "subtitle": subtitle,
        "introduction": bk["introduction"], "aliases": aliases,
        "chapters": [{"number": c["number"], "verses": [v["text"] for v in c["verses"]]} for c in bk["chapters"]],
    })

out = sys.argv[2] if len(sys.argv) > 2 else "bom.json"
json.dump({"volume": {"id": "book_of_mormon", "module": "BookOfMormon"},
           "front_matter": {"title_page": front["title_page"],
                            "testimony_of_three_witnesses": front["three_witnesses"],
                            "testimony_of_eight_witnesses": front["eight_witnesses"]},
           "books": volume_books},
          open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

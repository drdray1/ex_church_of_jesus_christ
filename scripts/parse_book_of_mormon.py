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
json.dump({"front_matter": front, "books": books}, open("bom.json","w",encoding="utf-8"), ensure_ascii=False, indent=1)

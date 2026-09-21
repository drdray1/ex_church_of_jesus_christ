# ExChurchOfJesusChrist

The scriptures of The Church of Jesus Christ of Latter-day Saints, compiled into
Elixir and modeled on
[churchofjesuschrist.org/study/scriptures](https://www.churchofjesuschrist.org/study/scriptures?lang=eng).

It contains all five standard works — 87 books, 1,582 chapters and 41,995
verses — compiled into the library, so it needs no network access, database
or runtime setup:

| Volume | Module | Books | Chapters | Verses |
|---|---|---|---|---|
| Old Testament (KJV) | `OldTestament` | 39 | 929 | 23,145 |
| New Testament (KJV) | `NewTestament` | 27 | 260 | 7,957 |
| Book of Mormon | `BookOfMormon` | 15 | 239 | 6,604 |
| Doctrine and Covenants | `DoctrineAndCovenants` | 1 | 138 sections | 3,654 |
| Pearl of Great Price | `PearlOfGreatPrice` | 5 | 16 | 635 |

Modules live under `ExChurchOfJesusChrist.Scriptures`. The Book of Mormon also
has its title page and the testimonies of the Three and Eight Witnesses, and
the Pearl of Great Price has the explanations of the Abraham facsimiles.

## Installation

```elixir
def deps do
  [
    {:ex_church_of_jesus_christ, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
alias ExChurchOfJesusChrist.Scriptures.BookOfMormon

# Scripture references, with abbreviations, ranges and lists
{:ok, [verse]} = BookOfMormon.lookup("1 Ne. 3:7")
verse.text
#=> "And it came to pass that I, Nephi, said unto my father: I will go and do the things which the Lord hath commanded..."
verse.url
#=> "https://www.churchofjesuschrist.org/study/scriptures/bofm/1-ne/3?lang=eng&id=p7#p7"

{:ok, verses} = BookOfMormon.lookup("Moroni 10:3-5")
{:ok, verses} = BookOfMormon.lookup("Alma 32:21, 27-28")
{:ok, verses} = BookOfMormon.lookup("Mosiah 2")   # whole chapter

# Direct access
{:ok, book}    = BookOfMormon.book("Helaman")     # or :helaman, "Hel.", "hel"
{:ok, chapter} = BookOfMormon.chapter(:alma, 32)
{:ok, verse}   = BookOfMormon.verse("2 Nephi", 2, 25)
BookOfMormon.verse!(:ether, 12, 27)

# Any volume, by reference
ExChurchOfJesusChrist.lookup("Ether 12:27")
ExChurchOfJesusChrist.lookup("John 3:16")
ExChurchOfJesusChrist.lookup("D&C 4:2")
ExChurchOfJesusChrist.lookup("JS—H 1:17")      # or "JS-H 1:17"
ExChurchOfJesusChrist.search("line upon line", volume: :doctrine_and_covenants)

# Everything, lazily
BookOfMormon.books()
BookOfMormon.stream() |> Enum.count()
#=> 6604

# Search (case-insensitive substring, or a Regex)
BookOfMormon.search("faith is not to have a perfect knowledge")
BookOfMormon.search(~r/\bliahona\b/i, book: :alma, limit: 5)

BookOfMormon.random_verse()
BookOfMormon.title_page()
BookOfMormon.testimony_of_three_witnesses()
```

Books have ids `:first_nephi`, `:second_nephi`, `:jacob`, `:enos`, `:jarom`,
`:omni`, `:words_of_mormon`, `:mosiah`, `:alma`, `:helaman`, `:third_nephi`,
`:fourth_nephi`, `:mormon`, `:ether` and `:moroni`.

## Text source

All five volumes come from
[bcbooks/scriptures-json](https://github.com/bcbooks/scriptures-json), a
dataset dedicated to the public domain. It has the current (2013) edition's
text, including the KJV Bible used by the Church. Chapter and verse numbering
matches churchofjesuschrist.org, and the tests check every volume's chapter and
verse counts (every section's, for the Doctrine and Covenants).

Text that is part of the scriptures is included:

- the Book of Mormon's title page, the testimonies of the Three and Eight
  Witnesses, and the original book headings and chapter headings (for example
  "The Record of Zeniff" before Mosiah 9), as `Book.introduction` and
  `Chapter.heading`
- Psalm titles such as "A Psalm of David.", as `Chapter.heading`
- the explanations of the Abraham facsimiles
  (`PearlOfGreatPrice.facsimile/1`)

The library does not include material the Church copyrights in its current
editions: the chapter and section summaries, footnotes, introductions, the
Testimony of the Prophet Joseph Smith, Official Declaration 2 and the study
helps (Topical Guide, Bible Dictionary and so on). Official Declaration 1 is
not in the dataset.

Book names follow the Church's table of contents, so references display as
"Psalms 23:1"; "Psalm 23" also works. The dataset uses straight quotes and
apostrophes, and small caps are written as capitals ("LORD").

## Regenerating the data

Each volume's text lives in generated modules under
`lib/ex_church_of_jesus_christ/scriptures/<volume>/data/`.
`scripts/parse_bcbooks.py` converts the dataset into volume JSON using the book
names, abbreviations, URL slugs and aliases in `scripts/book_metadata.json`,
and `scripts/generate_volume.py` turns that JSON into Elixir (its docstring
documents the JSON format):

```bash
python scripts/parse_bcbooks.py --download ../bcbooks-src
python scripts/parse_bcbooks.py ../bcbooks-src ../bcbooks-out
for f in ../bcbooks-out/*.json; do python scripts/generate_volume.py "$f"; done
```

## Adding a volume

1. Add the volume's books to `scripts/book_metadata.json`, and produce volume
   JSON from a public-domain source (extend `scripts/parse_bcbooks.py` or add a
   parser of your own).
2. Run `scripts/generate_volume.py` on it.
3. Add a module that calls `use ExChurchOfJesusChrist.Scriptures.Volume` (see
   `ExChurchOfJesusChrist.Scriptures.BookOfMormon`), and list it in
   `ExChurchOfJesusChrist.Scriptures`.
4. Add a test that checks the official chapter and verse counts.

## Roadmap

- Public-domain footnotes and cross-references (from the 1920/1921 editions)
  and public-domain Bible study helps.

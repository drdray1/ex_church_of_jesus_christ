# ExChurchOfJesusChrist

The scriptures of The Church of Jesus Christ of Latter-day Saints, compiled into
Elixir and modeled on
[churchofjesuschrist.org/study/scriptures](https://www.churchofjesuschrist.org/study/scriptures?lang=eng).

**Version 0.1 contains the complete Book of Mormon:** all 15 books, 239
chapters and 6,604 verses, plus the title page and the testimonies of the
Three and Eight Witnesses. The text is compiled into the library, so it needs
no network access, database or runtime setup.

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

The verse text is the public-domain edition published by
[Project Gutenberg (eBook #17)](https://www.gutenberg.org/ebooks/17). Its
chapter and verse numbering matches the current edition on
churchofjesuschrist.org, and the verse counts are checked in the test suite.

The library does not include material the Church copyrights in its current
edition: the introduction, chapter summaries, footnotes, the Testimony of the
Prophet Joseph Smith and the explanatory notes. The short headings that begin
some chapters (for example before Mosiah 9 and Alma 5) are also missing,
because the source text leaves them out.

## Regenerating the data

Each volume's text lives in generated modules under
`lib/ex_church_of_jesus_christ/scriptures/<volume>/data/`. A per-source parser
writes volume JSON, and `scripts/generate_volume.py` turns that JSON into
Elixir (its docstring documents the JSON format). For the Book of Mormon:

```bash
curl -sL -o bom.txt https://www.gutenberg.org/cache/epub/17/pg17.txt
python scripts/parse_book_of_mormon.py bom.txt bom.json
python scripts/generate_volume.py bom.json
```

## Adding a volume

1. Write `scripts/parse_<volume>.py` to produce volume JSON from a
   public-domain source.
2. Run `scripts/generate_volume.py` on it.
3. Add a module that calls `use ExChurchOfJesusChrist.Scriptures.Volume` (see
   `ExChurchOfJesusChrist.Scriptures.BookOfMormon`), and list it in
   `ExChurchOfJesusChrist.Scriptures`.
4. Add a test that checks the official chapter and verse counts.

## Roadmap

Later versions will add the other standard works: the Old Testament, the New
Testament, the Doctrine and Covenants and the Pearl of Great Price.

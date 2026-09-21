defmodule ExChurchOfJesusChrist.Scriptures.OldTestamentTest do
  use ExUnit.Case, async: true

  alias ExChurchOfJesusChrist.Scriptures
  alias ExChurchOfJesusChrist.Scriptures.{Chapter, OldTestament}

  doctest OldTestament

  # Chapter and verse counts of the King James Version.
  @expected [
    genesis: {50, 1533},
    exodus: {40, 1213},
    leviticus: {27, 859},
    numbers: {36, 1288},
    deuteronomy: {34, 959},
    joshua: {24, 658},
    judges: {21, 618},
    ruth: {4, 85},
    first_samuel: {31, 810},
    second_samuel: {24, 695},
    first_kings: {22, 816},
    second_kings: {25, 719},
    first_chronicles: {29, 942},
    second_chronicles: {36, 822},
    ezra: {10, 280},
    nehemiah: {13, 406},
    esther: {10, 167},
    job: {42, 1070},
    psalms: {150, 2461},
    proverbs: {31, 915},
    ecclesiastes: {12, 222},
    song_of_solomon: {8, 117},
    isaiah: {66, 1292},
    jeremiah: {52, 1364},
    lamentations: {5, 154},
    ezekiel: {48, 1273},
    daniel: {12, 357},
    hosea: {14, 197},
    joel: {3, 73},
    amos: {9, 146},
    obadiah: {1, 21},
    jonah: {4, 48},
    micah: {7, 105},
    nahum: {3, 47},
    habakkuk: {3, 56},
    zephaniah: {3, 53},
    haggai: {2, 38},
    zechariah: {14, 211},
    malachi: {4, 55}
  ]

  test "has all 39 books in order with official chapter and verse counts" do
    books = OldTestament.books()
    assert Enum.map(books, & &1.id) == Keyword.keys(@expected)
    assert Enum.map(books, & &1.order) == Enum.to_list(1..39)

    for book <- books do
      assert {book.chapter_count, book.verse_count} == @expected[book.id], "#{book.name}"
    end

    assert OldTestament.chapter_count() == 929
    assert OldTestament.verse_count() == 23_145
  end

  test "every chapter is numbered sequentially and every verse has clean text" do
    for id <- OldTestament.book_ids() do
      {:ok, chapters} = OldTestament.chapters(id)
      assert Enum.map(chapters, & &1.number) == Enum.to_list(1..length(chapters))

      for %Chapter{verses: verses} <- chapters do
        assert Enum.map(verses, & &1.number) == Enum.to_list(1..length(verses))

        for verse <- verses do
          assert String.length(verse.text) > 5, verse.reference
          assert verse.text == String.trim(verse.text), verse.reference
          refute verse.text =~ ~r/\d+:\d+/, verse.reference
          refute verse.text =~ ~r/\s{2}|\*|Gutenberg/, verse.reference
        end
      end
    end
  end

  test "first and last verses" do
    assert OldTestament.verse!(:genesis, 1, 1).text ==
             "In the beginning God created the heaven and the earth."

    assert OldTestament.verse!(:genesis, 50, 26).text =~ ~r/he was put in a coffin in Egypt\.$/
    assert OldTestament.verse!(:psalms, 1, 1).text =~ ~r/^Blessed is the man that walketh not/
    assert OldTestament.verse!(:psalms, 150, 6).text =~ ~r/Praise ye the LORD\.$/
    assert OldTestament.verse!(:obadiah, 1, 21).text =~ ~r/the kingdom shall be the LORD’s\.$/

    assert OldTestament.verse!(:malachi, 4, 6).text =~
             ~r/lest I come and smite the earth with a curse\.$/
  end

  test "verses that were run together in the source text are split" do
    assert OldTestament.verse!(:genesis, 1, 14).text =~ ~r/and for days, and years:$/
    assert OldTestament.verse!(:genesis, 1, 15).text =~ ~r/^And let them be for lights/

    assert OldTestament.verse!(:joshua, 12, 16).text ==
             "The king of Makkedah, one; the king of Bethel, one;"

    assert OldTestament.verse!(:joshua, 12, 17).text =~ ~r/^The king of Tappuah, one;/
  end

  test "Psalms are numbered without superscriptions" do
    assert OldTestament.verse!(:psalms, 3, 1).text =~ ~r/^Lord, how are they increased/

    assert OldTestament.verse!(:psalms, 23, 1).text ==
             "The LORD is my shepherd; I shall not want."

    assert length(OldTestament.chapter!(:psalms, 119).verses) == 176
    assert length(OldTestament.chapter!(:psalms, 117).verses) == 2
  end

  test "book resolution" do
    for ref <- [:first_samuel, "1 Samuel", "1 Sam.", "1sam", "first samuel", "I Samuel"] do
      assert {:ok, %{id: :first_samuel}} = OldTestament.book(ref)
    end

    for ref <- ["Psalms", "Psalm", "Ps.", "ps"] do
      assert {:ok, %{id: :psalms}} = OldTestament.book(ref)
    end

    for ref <- ["Song of Solomon", "Song", "Song of Songs", "Canticles", "song-of-solomon"] do
      assert {:ok, %{id: :song_of_solomon}} = OldTestament.book(ref)
    end

    assert {:ok, %{id: :second_kings}} = OldTestament.book("2 Kgs.")
    assert {:ok, %{id: :ecclesiastes}} = OldTestament.book("Eccl.")
    assert {:error, :book_not_found} = OldTestament.book(:alma)
  end

  test "reference lookups" do
    assert [%{reference: "Exodus 20:3"}] = OldTestament.lookup!("Ex. 20:3")

    assert OldTestament.lookup!("Prov. 3:5-6") |> Enum.map(& &1.reference) ==
             ["Proverbs 3:5", "Proverbs 3:6"]

    assert length(OldTestament.lookup!("Isa. 53")) == 12
    assert [%{reference: "Malachi 3:10"}] = OldTestament.lookup!("Mal. 3:10")
    assert [%{reference: "Job 19:25"}] = OldTestament.lookup!("Job 19:25")
    assert {:error, :chapter_not_found} = OldTestament.lookup("Obad. 2:1")
    assert {:error, :verse_not_found} = OldTestament.lookup("Obad. 1:22")
  end

  test "urls point at churchofjesuschrist.org" do
    assert OldTestament.verse!("1 Sam.", 16, 7).url ==
             "https://www.churchofjesuschrist.org/study/scriptures/ot/1-sam/16?lang=eng&id=p7#p7"

    assert OldTestament.chapter!("Ps.", 23).url ==
             "https://www.churchofjesuschrist.org/study/scriptures/ot/ps/23?lang=eng"
  end

  test "is routed to by the cross-volume API" do
    assert {:ok, [%{volume: :old_testament}]} = Scriptures.lookup("Gen. 1:1")
    assert [%{reference: "Genesis 1:1"}] = Scriptures.search("In the beginning God created")
  end
end

defmodule ExChurchOfJesusChrist.Scriptures.BookOfMormonTest do
  use ExUnit.Case, async: true

  alias ExChurchOfJesusChrist.Scriptures.{BookOfMormon, Chapter, Verse}

  doctest BookOfMormon

  # Chapter and verse counts of the official edition.
  @expected %{
    first_nephi: {22, 618},
    second_nephi: {33, 779},
    jacob: {7, 203},
    enos: {1, 27},
    jarom: {1, 15},
    omni: {1, 30},
    words_of_mormon: {1, 18},
    mosiah: {29, 785},
    alma: {63, 1975},
    helaman: {16, 497},
    third_nephi: {30, 785},
    fourth_nephi: {1, 49},
    mormon: {9, 227},
    ether: {15, 433},
    moroni: {10, 163}
  }

  test "has all 15 books in order with official chapter and verse counts" do
    books = BookOfMormon.books()
    assert Enum.map(books, & &1.order) == Enum.to_list(1..15)

    for book <- books do
      assert {book.chapter_count, book.verse_count} == @expected[book.id], "#{book.name}"
    end
  end

  test "every chapter is numbered sequentially and every verse has text" do
    for id <- BookOfMormon.book_ids() do
      {:ok, chapters} = BookOfMormon.chapters(id)
      assert Enum.map(chapters, & &1.number) == Enum.to_list(1..length(chapters))

      for %Chapter{verses: verses} <- chapters do
        assert Enum.map(verses, & &1.number) == Enum.to_list(1..length(verses))
        assert Enum.all?(verses, &(String.length(&1.text) > 5))
        refute Enum.any?(verses, &Regex.match?(~r/\d+:\d+/, &1.text))
      end
    end
  end

  test "first and last verses" do
    assert BookOfMormon.verse!(:first_nephi, 1, 1).text =~
             ~r/^I, Nephi, having been born of goodly parents/

    assert BookOfMormon.verse!(:moroni, 10, 34).text =~
             ~r/the Eternal Judge of both quick and dead\. Amen\.$/
  end

  test "verses that were run together in the source text are split" do
    assert BookOfMormon.verse!(:first_nephi, 2, 12).text =~ ~r/who had created them\.$/
    assert BookOfMormon.verse!(:first_nephi, 2, 13).text =~ ~r/^Neither did they believe/
  end

  test "book resolution" do
    for ref <- [:third_nephi, "3 Nephi", "3 Ne.", "3ne", "third nephi", "III Nephi"] do
      assert {:ok, %{id: :third_nephi}} = BookOfMormon.book(ref)
    end

    assert {:ok, %{id: :words_of_mormon}} = BookOfMormon.book("W of M")
    assert {:error, :book_not_found} = BookOfMormon.book(:genesis)
    assert_raise ArgumentError, fn -> BookOfMormon.book!("Genesis") end
  end

  test "lookup errors" do
    assert {:error, :chapter_not_found} = BookOfMormon.lookup("Enos 2:1")
    assert {:error, :verse_not_found} = BookOfMormon.lookup("Enos 1:28")
    assert {:error, :verse_not_found} = BookOfMormon.lookup("Enos 1:0")
    assert {:error, :book_not_found} = BookOfMormon.lookup("Exodus 3:14")
    assert {:error, :invalid_reference} = BookOfMormon.lookup("Alma 32:30-20")
    assert {:error, :invalid_reference} = BookOfMormon.lookup("nonsense")
  end

  test "chapter lookup returns every verse" do
    assert {:ok, verses} = BookOfMormon.lookup("Words of Mormon 1")
    assert length(verses) == 18
  end

  test "urls point at churchofjesuschrist.org" do
    %Verse{} = verse = BookOfMormon.verse!("Alma", 32, 21)

    assert verse.url ==
             "https://www.churchofjesuschrist.org/study/scriptures/bofm/alma/32?lang=eng&id=p21#p21"

    assert BookOfMormon.chapter!("1 Ne", 3).url ==
             "https://www.churchofjesuschrist.org/study/scriptures/bofm/1-ne/3?lang=eng"

    assert to_string(%{verse | text: "x"}) == "Alma 32:21 x"
  end

  test "search" do
    assert length(BookOfMormon.search("and it came to pass", limit: 5)) == 5

    assert [%{book: :moroni}] =
             BookOfMormon.search("by the power of the Holy Ghost ye may know the truth")
  end

  test "front matter" do
    assert ["THE BOOK OF MORMON" | _] = BookOfMormon.title_page()
    assert "DAVID WHITMER" in BookOfMormon.testimony_of_three_witnesses()
    assert "HYRUM SMITH" in BookOfMormon.testimony_of_eight_witnesses()
  end
end

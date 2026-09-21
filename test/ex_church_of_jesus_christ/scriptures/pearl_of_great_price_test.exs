defmodule ExChurchOfJesusChrist.Scriptures.PearlOfGreatPriceTest do
  use ExUnit.Case, async: true

  alias ExChurchOfJesusChrist.Scriptures.PearlOfGreatPrice

  doctest PearlOfGreatPrice

  # Chapter and verse counts of the current edition.
  @expected [
    moses: {8, 356},
    abraham: {5, 136},
    joseph_smith_matthew: {1, 55},
    joseph_smith_history: {1, 75},
    articles_of_faith: {1, 13}
  ]

  test "has all five books in order with the current edition's counts" do
    books = PearlOfGreatPrice.books()
    assert Enum.map(books, &{&1.id, {&1.chapter_count, &1.verse_count}}) == @expected
  end

  test "every chapter and verse is numbered sequentially and has text" do
    for id <- PearlOfGreatPrice.book_ids() do
      {:ok, chapters} = PearlOfGreatPrice.chapters(id)
      assert Enum.map(chapters, & &1.number) == Enum.to_list(1..length(chapters))

      for %{verses: verses} <- chapters do
        assert Enum.map(verses, & &1.number) == Enum.to_list(1..length(verses))
        assert Enum.all?(verses, &(String.length(&1.text) > 5))
        refute Enum.any?(verses, &Regex.match?(~r/\d+:\d+/, &1.text))
      end
    end
  end

  test "reference forms" do
    for ref <- ["JS—H 1:17", "JS-H 1:17", "js h 1:17", "Joseph Smith—History 1:17"] do
      assert {:ok, [%{book: :joseph_smith_history, chapter: 1, number: 17}]} =
               PearlOfGreatPrice.lookup(ref)
    end

    assert {:ok, [%{book: :joseph_smith_matthew}]} = PearlOfGreatPrice.lookup("JS—M 1:4")
    assert {:ok, [%{book: :abraham}]} = PearlOfGreatPrice.lookup("Abr. 3:22")
    assert {:ok, verses} = PearlOfGreatPrice.lookup("A of F 1")
    assert length(verses) == 13
    assert hd(verses).text =~ ~r/^We believe in God, the Eternal Father/
  end

  test "facsimiles" do
    for n <- 1..3 do
      assert ["A Facsimile from the Book of Abraham No. " <> _ | explanations] =
               PearlOfGreatPrice.facsimile(n)

      assert explanations != []
    end
  end
end

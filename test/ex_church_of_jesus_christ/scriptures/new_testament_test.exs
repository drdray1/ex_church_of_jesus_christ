defmodule ExChurchOfJesusChrist.Scriptures.NewTestamentTest do
  use ExUnit.Case, async: true

  alias ExChurchOfJesusChrist.Scriptures
  alias ExChurchOfJesusChrist.Scriptures.{Chapter, NewTestament}

  doctest NewTestament

  # Chapter and verse counts of the King James Version.
  @expected [
    matthew: {28, 1071},
    mark: {16, 678},
    luke: {24, 1151},
    john: {21, 879},
    acts: {28, 1007},
    romans: {16, 433},
    first_corinthians: {16, 437},
    second_corinthians: {13, 257},
    galatians: {6, 149},
    ephesians: {6, 155},
    philippians: {4, 104},
    colossians: {4, 95},
    first_thessalonians: {5, 89},
    second_thessalonians: {3, 47},
    first_timothy: {6, 113},
    second_timothy: {4, 83},
    titus: {3, 46},
    philemon: {1, 25},
    hebrews: {13, 303},
    james: {5, 108},
    first_peter: {5, 105},
    second_peter: {3, 61},
    first_john: {5, 105},
    second_john: {1, 13},
    third_john: {1, 14},
    jude: {1, 25},
    revelation: {22, 404}
  ]

  test "has all 27 books in order with official chapter and verse counts" do
    books = NewTestament.books()
    assert Enum.map(books, & &1.id) == Keyword.keys(@expected)
    assert Enum.map(books, & &1.order) == Enum.to_list(1..27)

    for book <- books do
      assert {book.chapter_count, book.verse_count} == @expected[book.id], "#{book.name}"
    end

    assert {NewTestament.chapter_count(), NewTestament.verse_count()} == {260, 7957}
  end

  test "every chapter is numbered sequentially and every verse has text" do
    for id <- NewTestament.book_ids() do
      {:ok, chapters} = NewTestament.chapters(id)
      assert Enum.map(chapters, & &1.number) == Enum.to_list(1..length(chapters))

      for %Chapter{verses: verses} <- chapters do
        assert Enum.map(verses, & &1.number) == Enum.to_list(1..length(verses))
        assert Enum.all?(verses, &(String.length(&1.text) > 5))
        assert Enum.all?(verses, &(&1.text == String.trim(&1.text)))
        refute Enum.any?(verses, &Regex.match?(~r/\d+:\d+/, &1.text))
        # Brackets are part of the KJV text (1 John 2:23 "[but]").
        refute Enum.any?(verses, &String.contains?(&1.text, ["  ", "*", "_"]))
      end
    end
  end

  test "first and last verses" do
    assert NewTestament.verse!(:matthew, 1, 1).text =~
             ~r/^The book of the generation of Jesus Christ, the son of David/

    assert NewTestament.verse!(:matthew, 28, 20).text =~
             ~r/even unto the end of the world\. Amen\.$/

    assert NewTestament.verse!(:john, 1, 1).text =~ ~r/^In the beginning was the Word/
    assert NewTestament.verse!(:third_john, 1, 14).text =~ ~r/Greet the friends by name\.$/

    assert NewTestament.verse!(:revelation, 22, 21).text ==
             "The grace of our Lord Jesus Christ be with you all. Amen."
  end

  test "verse boundaries" do
    assert NewTestament.verse!(:matthew, 1, 2).text ==
             "Abraham begat Isaac; and Isaac begat Jacob; and Jacob begat Judas and his brethren;"

    assert NewTestament.verse!(:matthew, 1, 3).text =~ ~r/^And Judas begat Phares/

    assert NewTestament.verse!(:revelation, 22, 18).text =~
             ~r/the plagues that are written in this book:$/

    assert NewTestament.verse!(:revelation, 22, 19).text =~ ~r/^And if any man shall take away/
  end

  test "book resolution" do
    for ref <- [
          :first_corinthians,
          "1 Corinthians",
          "1 Cor.",
          "1cor",
          "first corinthians",
          "I Corinthians"
        ] do
      assert {:ok, %{id: :first_corinthians}} = NewTestament.book(ref)
    end

    for ref <- ["Revelation", "Rev.", "revelations", "Apocalypse"] do
      assert {:ok, %{id: :revelation}} = NewTestament.book(ref)
    end

    assert {:ok, %{id: :matthew}} = NewTestament.book("Mt")
    assert {:ok, %{id: :philippians}} = NewTestament.book("Philip.")
    assert {:ok, %{id: :philemon}} = NewTestament.book("Philem.")
    assert {:ok, %{id: :first_john}} = NewTestament.book("1 Jn.")
    assert {:ok, %{id: :james}} = NewTestament.book("Jas")
    assert {:error, :book_not_found} = NewTestament.book(:alma)
    assert {:error, :book_not_found} = NewTestament.book("Jacob")
  end

  test "reference lookups" do
    assert ["1 Corinthians 13:4", "1 Corinthians 13:5"] =
             NewTestament.lookup!("1 Cor. 13:4-5") |> Enum.map(& &1.reference)

    assert [%{text: "Jesus wept."}] = NewTestament.lookup!("Jn 11:35")
    assert {:ok, verses} = NewTestament.lookup("3 Jn. 1")
    assert length(verses) == 14
    assert {:error, :verse_not_found} = NewTestament.lookup("3 John 1:15")
    assert {:error, :chapter_not_found} = NewTestament.lookup("Jude 2:1")

    assert NewTestament.chapter!("1 Thes.", 5).url ==
             "https://www.churchofjesuschrist.org/study/scriptures/nt/1-thes/5?lang=eng"
  end

  test "routed through Scriptures" do
    assert {:ok, [%{volume: :new_testament, reference: "Hebrews 11:1"}]} =
             Scriptures.lookup("Heb. 11:1")

    assert [%{reference: "John 11:35"}] = Scriptures.search("Jesus wept", volume: :new_testament)
  end
end

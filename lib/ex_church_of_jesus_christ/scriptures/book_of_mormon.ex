defmodule ExChurchOfJesusChrist.Scriptures.BookOfMormon do
  @moduledoc """
  The complete text of the Book of Mormon: Another Testament of Jesus Christ.

  All 15 books, 239 chapters and 6,604 verses are compiled into the library, so
  every function here works offline and without any runtime setup. The shared
  reading API is documented in `ExChurchOfJesusChrist.Scriptures.Volume`.

  Books can be identified by id atom (`:first_nephi`), name (`"1 Nephi"`),
  abbreviation (`"1 Ne."`) or a common alias (`"moro"`), case-insensitively.

  ## Examples

      iex> {:ok, [verse]} = BookOfMormon.lookup("1 Ne. 3:7")
      iex> verse.reference
      "1 Nephi 3:7"

      iex> BookOfMormon.lookup!("Alma 32:21, 27-28") |> Enum.map(& &1.reference)
      ["Alma 32:21", "Alma 32:27", "Alma 32:28"]

      iex> BookOfMormon.verse!("2 Nephi", 2, 25).text
      "Adam fell that men might be; and men are, that they might have joy."

      iex> {:ok, book} = BookOfMormon.book("hel.")
      iex> {book.id, book.chapter_count}
      {:helaman, 16}

      iex> BookOfMormon.chapter!("Alma", 32).verses |> length()
      43

      iex> BookOfMormon.parse_reference("Moro. 10:3-5")
      {:ok, %{book: :moroni, chapter: 10, verses: [3, 4, 5]}}

      iex> BookOfMormon.search(~r/\\bliahona\\b/i, book: :alma) |> Enum.map(& &1.reference)
      ["Alma 37:38"]

      iex> {BookOfMormon.chapter_count(), BookOfMormon.verse_count()}
      {239, 6604}
  """

  use ExChurchOfJesusChrist.Scriptures.Volume,
    id: :book_of_mormon,
    name: "Book of Mormon",
    url_path: "bofm",
    data: ExChurchOfJesusChrist.Scriptures.BookOfMormon.Data

  @doc """
  The title page of the Book of Mormon, one string per paragraph.
  """
  @spec title_page() :: [String.t()]
  def title_page, do: front_matter().title_page

  @doc """
  The Testimony of Three Witnesses: the testimony followed by the witnesses'
  names.
  """
  @spec testimony_of_three_witnesses() :: [String.t()]
  def testimony_of_three_witnesses, do: front_matter().testimony_of_three_witnesses

  @doc """
  The Testimony of Eight Witnesses: the testimony followed by the witnesses'
  names.
  """
  @spec testimony_of_eight_witnesses() :: [String.t()]
  def testimony_of_eight_witnesses, do: front_matter().testimony_of_eight_witnesses
end

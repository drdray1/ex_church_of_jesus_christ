defmodule ExChurchOfJesusChrist.Scriptures.OldTestament do
  @moduledoc """
  The complete text of the Old Testament, King James Version.

  All 39 books, 929 chapters and 23,145 verses are compiled into the library,
  so every function here works offline and without any runtime setup. The
  shared reading API is documented in `ExChurchOfJesusChrist.Scriptures.Volume`.

  Books can be identified by id atom (`:first_samuel`), name (`"1 Samuel"`),
  abbreviation (`"1 Sam."`) or a common alias (`"psalm"`, `"canticles"`),
  case-insensitively.

  Verse numbering follows the KJV. Psalm titles (such as "A Psalm of David.")
  are not numbered verses; they are the `heading` of their chapter.

  ## Examples

      iex> OldTestament.verse!("Genesis", 1, 1).text
      "In the beginning God created the heaven and the earth."

      iex> {:ok, [verse]} = OldTestament.lookup("Gen. 1:1")
      iex> verse.reference
      "Genesis 1:1"

      iex> OldTestament.lookup!("Ps. 23") |> hd() |> Map.get(:text)
      "The LORD is my shepherd; I shall not want."

      iex> OldTestament.lookup!("Isa. 53:3-5") |> Enum.map(& &1.reference)
      ["Isaiah 53:3", "Isaiah 53:4", "Isaiah 53:5"]

      iex> OldTestament.parse_reference("1 Sam. 16:7")
      {:ok, %{book: :first_samuel, chapter: 16, verses: [7]}}

      iex> {:ok, book} = OldTestament.book("song")
      iex> {book.id, book.name, book.chapter_count}
      {:song_of_solomon, "Song of Solomon", 8}

      iex> {OldTestament.chapter_count(), OldTestament.verse_count()}
      {929, 23145}
  """

  use ExChurchOfJesusChrist.Scriptures.Volume,
    id: :old_testament,
    name: "Old Testament",
    url_path: "ot",
    data: ExChurchOfJesusChrist.Scriptures.OldTestament.Data
end

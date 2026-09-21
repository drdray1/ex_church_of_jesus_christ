defmodule ExChurchOfJesusChrist.Scriptures.NewTestament do
  @moduledoc """
  The complete text of the New Testament (King James Version).

  All 27 books, 260 chapters and 7,957 verses are compiled into the library, so
  every function here works offline and without any runtime setup. The shared
  reading API is documented in `ExChurchOfJesusChrist.Scriptures.Volume`.

  Books can be identified by id atom (`:first_corinthians`), name
  (`"1 Corinthians"`), abbreviation (`"1 Cor."`) or a common alias (`"1cor"`),
  case-insensitively.

  ## Examples

      iex> NewTestament.verse!("John", 3, 16).text
      "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life."

      iex> NewTestament.lookup!("Matt. 5:14-16") |> Enum.map(& &1.reference)
      ["Matthew 5:14", "Matthew 5:15", "Matthew 5:16"]

      iex> {:ok, [verse]} = NewTestament.lookup("James 1:5")
      iex> verse.url
      "https://www.churchofjesuschrist.org/study/scriptures/nt/james/1?lang=eng&id=p5#p5"

      iex> {:ok, book} = NewTestament.book("1 Cor.")
      iex> {book.id, book.chapter_count}
      {:first_corinthians, 16}

      iex> NewTestament.parse_reference("Rev. 22:20-21")
      {:ok, %{book: :revelation, chapter: 22, verses: [20, 21]}}

      iex> NewTestament.verse!(:john, 11, 35).text
      "Jesus wept."

      iex> {NewTestament.chapter_count(), NewTestament.verse_count()}
      {260, 7957}
  """

  use ExChurchOfJesusChrist.Scriptures.Volume,
    id: :new_testament,
    name: "New Testament",
    url_path: "nt",
    data: ExChurchOfJesusChrist.Scriptures.NewTestament.Data
end

defmodule ExChurchOfJesusChrist do
  @moduledoc """
  Scriptures of The Church of Jesus Christ of Latter-day Saints, compiled into
  Elixir, modeled on https://www.churchofjesuschrist.org/study/scriptures.

  This version has the complete Book of Mormon; see
  `ExChurchOfJesusChrist.Scriptures.BookOfMormon`.

      iex> {:ok, [verse]} = ExChurchOfJesusChrist.lookup("Mosiah 2:17")
      iex> verse.text
      "And behold, I tell you these things that ye may learn wisdom; that ye may learn that when ye are in the service of your fellow beings ye are only in the service of your God."
  """

  alias ExChurchOfJesusChrist.Scriptures.BookOfMormon

  @doc """
  Looks up a scripture reference such as `"Alma 32:21"`.

  See `ExChurchOfJesusChrist.Scriptures.BookOfMormon.lookup/1`.
  """
  defdelegate lookup(reference), to: BookOfMormon

  @doc """
  Searches the scriptures for verses containing `query`.

  See `ExChurchOfJesusChrist.Scriptures.BookOfMormon.search/2`.
  """
  defdelegate search(query, opts \\ []), to: BookOfMormon
end

defmodule ExChurchOfJesusChrist do
  @moduledoc """
  Scriptures of The Church of Jesus Christ of Latter-day Saints, compiled into
  Elixir, modeled on https://www.churchofjesuschrist.org/study/scriptures.

  See `ExChurchOfJesusChrist.Scriptures` for the list of volumes and for
  cross-volume lookups, and each volume module (such as
  `ExChurchOfJesusChrist.Scriptures.BookOfMormon`) for volume-specific access.

      iex> {:ok, [verse]} = ExChurchOfJesusChrist.lookup("Mosiah 2:17")
      iex> verse.text
      "And behold, I tell you these things that ye may learn wisdom; that ye may learn that when ye are in the service of your fellow beings ye are only in the service of your God."
  """

  alias ExChurchOfJesusChrist.Scriptures

  @doc """
  Looks up a scripture reference such as `"Alma 32:21"` in any volume.

  See `ExChurchOfJesusChrist.Scriptures.lookup/1`.
  """
  defdelegate lookup(reference), to: Scriptures

  @doc """
  Searches every volume for verses matching `query`.

  See `ExChurchOfJesusChrist.Scriptures.search/2`.
  """
  defdelegate search(query, opts \\ []), to: Scriptures
end

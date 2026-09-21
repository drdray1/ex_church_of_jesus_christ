defmodule ExChurchOfJesusChrist.Scriptures.DoctrineAndCovenants do
  @moduledoc """
  The Doctrine and Covenants: all 138 sections and 3,654 verses.

  Sections are the "chapters" of the single book `:doctrine_and_covenants`, so
  references read `"D&C 76:22"`. The shared reading API is documented in
  `ExChurchOfJesusChrist.Scriptures.Volume`.

  The Official Declarations are not included: Official Declaration 2 (1978)
  is under copyright, and so are the Church's section headings and footnotes.

  ## Examples

      iex> DoctrineAndCovenants.lookup!("D&C 4:2") |> hd() |> Map.get(:text)
      "Therefore, O ye that embark in the service of God, see that ye serve him with all your heart, might, mind and strength, that ye may stand blameless before God at the last day."

      iex> DoctrineAndCovenants.lookup!("Doctrine and Covenants 76:22-24") |> length()
      3

      iex> DoctrineAndCovenants.chapter!("D&C", 89).url
      "https://www.churchofjesuschrist.org/study/scriptures/dc-testament/dc/89?lang=eng"

      iex> {DoctrineAndCovenants.chapter_count(), DoctrineAndCovenants.verse_count()}
      {138, 3654}
  """

  use ExChurchOfJesusChrist.Scriptures.Volume,
    id: :doctrine_and_covenants,
    name: "Doctrine and Covenants",
    url_path: "dc-testament",
    data: ExChurchOfJesusChrist.Scriptures.DoctrineAndCovenants.Data
end

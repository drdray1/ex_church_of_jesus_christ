defmodule ExChurchOfJesusChrist.Scriptures.PearlOfGreatPrice do
  @moduledoc """
  The Pearl of Great Price: Moses, Abraham, Joseph Smith—Matthew,
  Joseph Smith—History and the Articles of Faith (16 chapters, 635 verses),
  plus the explanations of the three facsimiles from the Book of Abraham.

  The shared reading API is documented in
  `ExChurchOfJesusChrist.Scriptures.Volume`.

  ## Examples

      iex> PearlOfGreatPrice.lookup!("Moses 1:39") |> hd() |> Map.get(:text)
      "For behold, this is my work and my glory—to bring to pass the immortality and eternal life of man."

      iex> PearlOfGreatPrice.lookup!("JS-H 1:17") |> hd() |> Map.get(:reference)
      "Joseph Smith—History 1:17"

      iex> PearlOfGreatPrice.lookup!("A of F 1:13") |> hd() |> Map.get(:url)
      "https://www.churchofjesuschrist.org/study/scriptures/pgp/a-of-f/1?lang=eng&id=p13#p13"

      iex> PearlOfGreatPrice.facsimile(1) |> hd()
      "A Facsimile from the Book of Abraham No. 1"
  """

  use ExChurchOfJesusChrist.Scriptures.Volume,
    id: :pearl_of_great_price,
    name: "Pearl of Great Price",
    url_path: "pgp",
    data: ExChurchOfJesusChrist.Scriptures.PearlOfGreatPrice.Data

  @doc """
  A facsimile from the Book of Abraham (1, 2 or 3): its title followed by the
  numbered explanations of the figures.
  """
  @spec facsimile(1..3) :: [String.t()]
  def facsimile(number) when number in 1..3,
    do: Map.fetch!(front_matter(), :"facsimile_#{number}")
end

defmodule ExChurchOfJesusChrist.Scriptures.Chapter do
  @moduledoc """
  A chapter of a book of scripture, with all of its verses.

  `heading` is text that is part of the scripture and comes before verse 1,
  such as a Psalm title ("A Psalm of David.") or the Book of Mormon's
  original chapter headings ("The Record of Zeniff..."). It is `nil` for most
  chapters.
  """

  alias ExChurchOfJesusChrist.Scriptures.Verse

  @enforce_keys [:book, :book_name, :number, :verses]
  defstruct [:volume, :book, :book_name, :number, :heading, :reference, :url, verses: []]

  @type t :: %__MODULE__{
          volume: atom(),
          book: atom(),
          book_name: String.t(),
          number: pos_integer(),
          heading: String.t() | nil,
          reference: String.t(),
          url: String.t(),
          verses: [Verse.t()]
        }
end

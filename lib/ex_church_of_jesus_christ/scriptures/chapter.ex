defmodule ExChurchOfJesusChrist.Scriptures.Chapter do
  @moduledoc """
  A chapter of a book of scripture, with all of its verses.
  """

  alias ExChurchOfJesusChrist.Scriptures.Verse

  @enforce_keys [:book, :book_name, :number, :verses]
  defstruct [:book, :book_name, :number, :reference, :url, verses: []]

  @type t :: %__MODULE__{
          book: atom(),
          book_name: String.t(),
          number: pos_integer(),
          reference: String.t(),
          url: String.t(),
          verses: [Verse.t()]
        }
end

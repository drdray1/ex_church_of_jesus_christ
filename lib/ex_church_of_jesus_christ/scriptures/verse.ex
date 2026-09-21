defmodule ExChurchOfJesusChrist.Scriptures.Verse do
  @moduledoc """
  A single verse of scripture.
  """

  @enforce_keys [:book, :book_name, :chapter, :number, :text]
  defstruct [:book, :book_name, :chapter, :number, :text, :reference, :url]

  @type t :: %__MODULE__{
          book: atom(),
          book_name: String.t(),
          chapter: pos_integer(),
          number: pos_integer(),
          text: String.t(),
          reference: String.t(),
          url: String.t()
        }

  defimpl String.Chars do
    def to_string(verse), do: "#{verse.reference} #{verse.text}"
  end
end

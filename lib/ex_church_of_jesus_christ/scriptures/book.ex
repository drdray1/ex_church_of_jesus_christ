defmodule ExChurchOfJesusChrist.Scriptures.Book do
  @moduledoc """
  A book of scripture, such as 1 Nephi or Alma.

  Chapters are not embedded in the struct; fetch them with
  `ExChurchOfJesusChrist.Scriptures.BookOfMormon.chapters/1`.
  """

  @enforce_keys [:id, :order, :name, :abbreviation, :title, :chapter_count, :verse_count]
  defstruct [
    :id,
    :order,
    :name,
    :abbreviation,
    :title,
    :subtitle,
    :chapter_count,
    :verse_count,
    :url,
    :volume,
    introduction: []
  ]

  @type t :: %__MODULE__{
          id: atom(),
          order: pos_integer(),
          name: String.t(),
          abbreviation: String.t(),
          title: String.t(),
          subtitle: String.t() | nil,
          chapter_count: pos_integer(),
          verse_count: pos_integer(),
          url: String.t(),
          volume: atom(),
          introduction: [String.t()]
        }
end

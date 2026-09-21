defmodule ExChurchOfJesusChrist.Scriptures do
  @moduledoc """
  Every volume of scripture in the library, and lookups that work across them.

  Book ids and names are unique across volumes, so a reference such as
  `"Alma 32:21"` is routed to the right volume automatically.
  """

  alias ExChurchOfJesusChrist.Scriptures.{Book, BookOfMormon, Verse, Volume}

  # In canonical order. Each module must `use ExChurchOfJesusChrist.Scriptures.Volume`.
  @volumes [
    ExChurchOfJesusChrist.Scriptures.OldTestament,
    BookOfMormon
  ]

  @doc """
  The volume modules, in canonical order.

      iex> ExChurchOfJesusChrist.Scriptures.volumes() |> Enum.map(& &1.id())
      [:old_testament, :book_of_mormon]
  """
  @spec volumes() :: [module()]
  def volumes, do: @volumes

  @doc """
  Finds a volume module by id atom.

      iex> ExChurchOfJesusChrist.Scriptures.volume(:book_of_mormon)
      {:ok, ExChurchOfJesusChrist.Scriptures.BookOfMormon}
  """
  @spec volume(atom()) :: {:ok, module()} | {:error, :volume_not_found}
  def volume(id) do
    case Enum.find(@volumes, &(&1.id() == id)) do
      nil -> {:error, :volume_not_found}
      module -> {:ok, module}
    end
  end

  @doc """
  Every book in every volume, in canonical order.
  """
  @spec books() :: [Book.t()]
  def books, do: Enum.flat_map(@volumes, & &1.books())

  @doc """
  Finds a book in any volume by id atom, name, abbreviation or alias.
  """
  @spec book(Volume.book_ref()) :: {:ok, Book.t()} | {:error, :book_not_found}
  def book(ref), do: first_found(& &1.book(ref))

  @doc """
  Looks up a scripture reference in whichever volume contains the book.

      iex> {:ok, [verse]} = ExChurchOfJesusChrist.Scriptures.lookup("Ether 12:27")
      iex> verse.volume
      :book_of_mormon
  """
  @spec lookup(String.t()) :: {:ok, [Verse.t()]} | {:error, Volume.error()}
  def lookup(reference), do: first_found(& &1.lookup(reference))

  @doc """
  Like `lookup/1` but raises `ArgumentError` on failure.
  """
  @spec lookup!(String.t()) :: [Verse.t()]
  def lookup!(reference), do: Volume.bang(lookup(reference), reference)

  @doc """
  Searches every volume. Accepts the options of the volume `search/2`
  functions plus `:volume` to restrict the search to one volume id.
  """
  @spec search(String.t() | Regex.t(), keyword()) :: [Verse.t()]
  def search(query, opts \\ []) do
    {volume, opts} = Keyword.pop(opts, :volume)
    {limit, opts} = Keyword.pop(opts, :limit)
    {book, _} = Keyword.pop(opts, :book)

    volumes =
      cond do
        volume -> Enum.filter(@volumes, &(&1.id() == volume))
        book -> Enum.filter(@volumes, &match?({:ok, _}, &1.book(book)))
        true -> @volumes
      end

    volumes
    |> Stream.flat_map(fn module ->
      module.search(query, Keyword.merge(opts, book: book, limit: limit) |> drop_nil())
    end)
    |> then(fn verses -> if limit, do: Enum.take(verses, limit), else: Enum.to_list(verses) end)
  end

  defp drop_nil(opts), do: Enum.reject(opts, fn {_, v} -> is_nil(v) end)

  # Returns the first result that isn't :book_not_found, or :book_not_found.
  defp first_found(fun) do
    Enum.find_value(@volumes, {:error, :book_not_found}, fn module ->
      case fun.(module) do
        {:error, :book_not_found} -> nil
        result -> result
      end
    end)
  end
end

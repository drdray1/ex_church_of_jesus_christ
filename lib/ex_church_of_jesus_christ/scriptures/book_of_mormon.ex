defmodule ExChurchOfJesusChrist.Scriptures.BookOfMormon do
  @moduledoc """
  The complete text of the Book of Mormon: Another Testament of Jesus Christ.

  All 15 books, 239 chapters and 6,604 verses are compiled into the library, so
  every function here works offline and without any runtime setup.

  Books can be identified by id atom (`:first_nephi`), name (`"1 Nephi"`),
  abbreviation (`"1 Ne."`) or a common alias (`"moro"`), case-insensitively.

  ## Examples

      iex> {:ok, [verse]} = BookOfMormon.lookup("1 Ne. 3:7")
      iex> verse.reference
      "1 Nephi 3:7"

      iex> {:ok, verse} = BookOfMormon.verse(:moroni, 10, 4)
      iex> String.starts_with?(verse.text, "And when ye shall receive these things")
      true
  """

  alias ExChurchOfJesusChrist.Scriptures.{Book, Chapter, Verse}
  alias __MODULE__.Data

  @base_url "https://www.churchofjesuschrist.org/study/scriptures/bofm"

  @data_modules [
    Data.FirstNephi,
    Data.SecondNephi,
    Data.Jacob,
    Data.Enos,
    Data.Jarom,
    Data.Omni,
    Data.WordsOfMormon,
    Data.Mosiah,
    Data.Alma,
    Data.Helaman,
    Data.ThirdNephi,
    Data.FourthNephi,
    Data.Mormon,
    Data.Ether,
    Data.Moroni
  ]

  @books Enum.map(@data_modules, fn module ->
           meta = module.metadata()
           chapters = module.chapters()

           {meta.id,
            %{
              module: module,
              aliases: meta.aliases,
              book: %Book{
                id: meta.id,
                order: meta.order,
                name: meta.name,
                abbreviation: meta.abbreviation,
                title: meta.title,
                subtitle: meta.subtitle,
                introduction: meta.introduction,
                chapter_count: length(chapters),
                verse_count:
                  chapters |> Enum.map(fn {_, verses} -> length(verses) end) |> Enum.sum(),
                url: "#{@base_url}/#{meta.url_slug}?lang=eng"
              },
              url_slug: meta.url_slug
            }}
         end)

  @book_map Map.new(@books)
  @book_ids Enum.map(@books, &elem(&1, 0))

  normalize = fn name ->
    name
    |> String.downcase()
    |> String.replace(".", "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  @name_index @books
              |> Enum.flat_map(fn {id, %{aliases: aliases, book: book}} ->
                [book.name, book.abbreviation, Atom.to_string(id) | aliases]
                |> Enum.map(&{normalize.(&1), id})
              end)
              |> Map.new()

  @type book_ref :: atom() | String.t() | Book.t()
  @type error :: :book_not_found | :chapter_not_found | :verse_not_found | :invalid_reference

  ## Books

  @doc """
  Returns every book in the Book of Mormon, in canonical order.

      iex> BookOfMormon.books() |> Enum.map(& &1.name) |> Enum.take(3)
      ["1 Nephi", "2 Nephi", "Jacob"]
  """
  @spec books() :: [Book.t()]
  def books, do: Enum.map(@book_ids, &@book_map[&1].book)

  @doc """
  Returns the id atoms of every book, in canonical order.
  """
  @spec book_ids() :: [atom()]
  def book_ids, do: @book_ids

  @doc """
  Finds a book by id, name, abbreviation or alias.

      iex> {:ok, book} = BookOfMormon.book("hel.")
      iex> {book.id, book.chapter_count}
      {:helaman, 16}

      iex> BookOfMormon.book("Genesis")
      {:error, :book_not_found}
  """
  @spec book(book_ref()) :: {:ok, Book.t()} | {:error, :book_not_found}
  def book(ref) do
    case resolve(ref) do
      {:ok, id} -> {:ok, @book_map[id].book}
      error -> error
    end
  end

  @doc """
  Like `book/1` but raises `ArgumentError` if the book does not exist.
  """
  @spec book!(book_ref()) :: Book.t()
  def book!(ref), do: bang(book(ref), ref)

  ## Chapters

  @doc """
  Returns every chapter of a book, with verses.

      iex> {:ok, chapters} = BookOfMormon.chapters(:enos)
      iex> length(chapters)
      1
  """
  @spec chapters(book_ref()) :: {:ok, [Chapter.t()]} | {:error, :book_not_found}
  def chapters(ref) do
    with {:ok, id} <- resolve(ref) do
      entry = @book_map[id]
      {:ok, Enum.map(entry.module.chapters(), &build_chapter(entry, &1))}
    end
  end

  @doc """
  Returns a single chapter of a book, with verses.

      iex> {:ok, chapter} = BookOfMormon.chapter("Alma", 32)
      iex> {chapter.reference, length(chapter.verses)}
      {"Alma 32", 43}
  """
  @spec chapter(book_ref(), pos_integer()) ::
          {:ok, Chapter.t()} | {:error, :book_not_found | :chapter_not_found}
  def chapter(ref, number) when is_integer(number) do
    with {:ok, id} <- resolve(ref),
         entry = @book_map[id],
         {:ok, raw} <- fetch_chapter(entry, number) do
      {:ok, build_chapter(entry, raw)}
    end
  end

  @doc """
  Like `chapter/2` but raises `ArgumentError` on failure.
  """
  @spec chapter!(book_ref(), pos_integer()) :: Chapter.t()
  def chapter!(ref, number), do: bang(chapter(ref, number), "#{inspect(ref)} #{number}")

  ## Verses

  @doc """
  Returns a single verse.

      iex> {:ok, verse} = BookOfMormon.verse("2 Nephi", 2, 25)
      iex> verse.text
      "Adam fell that men might be; and men are, that they might have joy."
  """
  @spec verse(book_ref(), pos_integer(), pos_integer()) :: {:ok, Verse.t()} | {:error, error()}
  def verse(ref, chapter, number) when is_integer(chapter) and is_integer(number) do
    with {:ok, id} <- resolve(ref),
         entry = @book_map[id],
         {:ok, {^chapter, texts}} <- fetch_chapter(entry, chapter),
         {:ok, text} <- fetch_verse(texts, number) do
      {:ok, build_verse(entry, chapter, number, text)}
    end
  end

  @doc """
  Like `verse/3` but raises `ArgumentError` on failure.
  """
  @spec verse!(book_ref(), pos_integer(), pos_integer()) :: Verse.t()
  def verse!(ref, chapter, number),
    do: bang(verse(ref, chapter, number), "#{inspect(ref)} #{chapter}:#{number}")

  @doc """
  Returns every verse of the Book of Mormon as a lazy stream, in order.

      iex> BookOfMormon.stream() |> Enum.count()
      6604
  """
  @spec stream() :: Enumerable.t(Verse.t())
  def stream do
    Stream.flat_map(@book_ids, fn id ->
      entry = @book_map[id]

      Stream.flat_map(entry.module.chapters(), fn {chapter, texts} ->
        texts
        |> Enum.with_index(1)
        |> Enum.map(fn {text, number} -> build_verse(entry, chapter, number, text) end)
      end)
    end)
  end

  @doc """
  Returns a uniformly random verse.
  """
  @spec random_verse() :: Verse.t()
  def random_verse do
    index = :rand.uniform(verse_count()) - 1
    stream() |> Stream.drop(index) |> Enum.at(0)
  end

  ## References

  @doc """
  Parses a scripture reference without looking up any text.

  Supported forms are `"Book C"`, `"Book C:V"`, `"Book C:V-W"` and
  comma-separated verse lists such as `"Book C:V,W-X"`.

      iex> BookOfMormon.parse_reference("Moro. 10:3-5")
      {:ok, %{book: :moroni, chapter: 10, verses: [3, 4, 5]}}

      iex> BookOfMormon.parse_reference("Mosiah 2")
      {:ok, %{book: :mosiah, chapter: 2, verses: :all}}
  """
  @spec parse_reference(String.t()) ::
          {:ok, %{book: atom(), chapter: pos_integer(), verses: :all | [pos_integer()]}}
          | {:error, :book_not_found | :invalid_reference}
  def parse_reference(reference) when is_binary(reference) do
    case Regex.run(~r/^\s*(.+?)\s+(\d+)(?:\s*:\s*([\d\s,\-–—]+))?\s*$/u, reference) do
      [_, name, chapter | rest] ->
        with {:ok, id} <- resolve(name),
             {:ok, verses} <- parse_verses(rest) do
          {:ok, %{book: id, chapter: String.to_integer(chapter), verses: verses}}
        end

      nil ->
        {:error, :invalid_reference}
    end
  end

  @doc """
  Looks up the verses named by a scripture reference.

  A chapter-only reference returns every verse in the chapter.

      iex> {:ok, verses} = BookOfMormon.lookup("Alma 32:21, 27-28")
      iex> Enum.map(verses, & &1.reference)
      ["Alma 32:21", "Alma 32:27", "Alma 32:28"]
  """
  @spec lookup(String.t()) :: {:ok, [Verse.t()]} | {:error, error()}
  def lookup(reference) do
    with {:ok, %{book: id, chapter: chapter, verses: numbers}} <- parse_reference(reference),
         entry = @book_map[id],
         {:ok, {^chapter, texts}} <- fetch_chapter(entry, chapter) do
      numbers = if numbers == :all, do: Enum.to_list(1..length(texts)), else: numbers

      Enum.reduce_while(numbers, {:ok, []}, fn number, {:ok, acc} ->
        case fetch_verse(texts, number) do
          {:ok, text} -> {:cont, {:ok, [build_verse(entry, chapter, number, text) | acc]}}
          error -> {:halt, error}
        end
      end)
      |> case do
        {:ok, verses} -> {:ok, Enum.reverse(verses)}
        error -> error
      end
    end
  end

  @doc """
  Like `lookup/1` but raises `ArgumentError` on failure.
  """
  @spec lookup!(String.t()) :: [Verse.t()]
  def lookup!(reference), do: bang(lookup(reference), reference)

  ## Search

  @doc """
  Searches the text of every verse.

  A string query matches case-insensitively as a substring; a `Regex` is
  matched as given.

  ## Options

    * `:book` - restrict the search to one book
    * `:limit` - return at most this many verses

  ## Examples

      iex> BookOfMormon.search("adam fell") |> Enum.map(& &1.reference)
      ["2 Nephi 2:25"]

      iex> BookOfMormon.search(~r/\\bliahona\\b/i, book: :alma) |> Enum.map(& &1.reference)
      ["Alma 37:38"]
  """
  @spec search(String.t() | Regex.t(), keyword()) :: [Verse.t()]
  def search(query, opts \\ []) do
    matcher =
      case query do
        %Regex{} = regex ->
          &Regex.match?(regex, &1)

        query when is_binary(query) ->
          needle = String.downcase(query)
          &String.contains?(String.downcase(&1), needle)
      end

    verses =
      case Keyword.get(opts, :book) do
        nil ->
          stream()

        ref ->
          {:ok, chapters} = chapters(book!(ref))
          Stream.flat_map(chapters, & &1.verses)
      end

    verses = Stream.filter(verses, &matcher.(&1.text))

    case Keyword.get(opts, :limit) do
      nil -> Enum.to_list(verses)
      limit -> Enum.take(verses, limit)
    end
  end

  ## Front matter

  @doc """
  The title page of the Book of Mormon, one string per paragraph.
  """
  @spec title_page() :: [String.t()]
  def title_page, do: Data.FrontMatter.title_page()

  @doc """
  The Testimony of Three Witnesses: the testimony paragraph(s) followed by the
  witnesses' names.
  """
  @spec testimony_of_three_witnesses() :: [String.t()]
  def testimony_of_three_witnesses, do: Data.FrontMatter.three_witnesses()

  @doc """
  The Testimony of Eight Witnesses: the testimony paragraph(s) followed by the
  witnesses' names.
  """
  @spec testimony_of_eight_witnesses() :: [String.t()]
  def testimony_of_eight_witnesses, do: Data.FrontMatter.eight_witnesses()

  ## Counts

  @doc """
  Total number of chapters in the Book of Mormon.

      iex> BookOfMormon.chapter_count()
      239
  """
  @spec chapter_count() :: pos_integer()
  def chapter_count,
    do: unquote(@books |> Enum.map(fn {_, e} -> e.book.chapter_count end) |> Enum.sum())

  @doc """
  Total number of verses in the Book of Mormon.

      iex> BookOfMormon.verse_count()
      6604
  """
  @spec verse_count() :: pos_integer()
  def verse_count,
    do: unquote(@books |> Enum.map(fn {_, e} -> e.book.verse_count end) |> Enum.sum())

  ## Helpers

  defp resolve(%Book{id: id}), do: resolve(id)
  defp resolve(id) when is_atom(id) and is_map_key(@book_map, id), do: {:ok, id}
  defp resolve(id) when is_atom(id), do: {:error, :book_not_found}

  defp resolve(name) when is_binary(name) do
    key =
      name
      |> String.downcase()
      |> String.replace(".", "")
      |> String.replace(~r/\s+/, " ")
      |> String.trim()

    case @name_index do
      %{^key => id} -> {:ok, id}
      _ -> {:error, :book_not_found}
    end
  end

  defp fetch_chapter(entry, number) do
    case List.keyfind(entry.module.chapters(), number, 0) do
      nil -> {:error, :chapter_not_found}
      chapter -> {:ok, chapter}
    end
  end

  defp fetch_verse(texts, number) when number >= 1 do
    case Enum.at(texts, number - 1) do
      nil -> {:error, :verse_not_found}
      text -> {:ok, text}
    end
  end

  defp fetch_verse(_texts, _number), do: {:error, :verse_not_found}

  defp parse_verses([]), do: {:ok, :all}

  defp parse_verses([spec]) do
    spec
    |> String.split(",", trim: true)
    |> Enum.reduce_while({:ok, []}, fn part, {:ok, acc} ->
      case part |> String.split(~r/[\-–—]/u) |> Enum.map(&Integer.parse(String.trim(&1))) do
        [{v, ""}] -> {:cont, {:ok, acc ++ [v]}}
        [{from, ""}, {to, ""}] when from <= to -> {:cont, {:ok, acc ++ Enum.to_list(from..to)}}
        _ -> {:halt, {:error, :invalid_reference}}
      end
    end)
  end

  defp build_chapter(entry, {number, texts}) do
    %Chapter{
      book: entry.book.id,
      book_name: entry.book.name,
      number: number,
      reference: "#{entry.book.name} #{number}",
      url: chapter_url(entry, number),
      verses:
        texts
        |> Enum.with_index(1)
        |> Enum.map(fn {text, verse} -> build_verse(entry, number, verse, text) end)
    }
  end

  defp build_verse(entry, chapter, number, text) do
    %Verse{
      book: entry.book.id,
      book_name: entry.book.name,
      chapter: chapter,
      number: number,
      text: text,
      reference: "#{entry.book.name} #{chapter}:#{number}",
      url: "#{@base_url}/#{entry.url_slug}/#{chapter}?lang=eng&id=p#{number}#p#{number}"
    }
  end

  defp chapter_url(entry, chapter), do: "#{@base_url}/#{entry.url_slug}/#{chapter}?lang=eng"

  defp bang({:ok, value}, _ref), do: value

  defp bang({:error, reason}, ref),
    do:
      raise(
        ArgumentError,
        "#{reason |> Atom.to_string() |> String.replace("_", " ")}: #{inspect(ref)}"
      )
end

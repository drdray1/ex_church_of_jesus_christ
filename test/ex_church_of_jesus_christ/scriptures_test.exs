defmodule ExChurchOfJesusChrist.ScripturesTest do
  use ExUnit.Case, async: true

  alias ExChurchOfJesusChrist.Scriptures

  doctest Scriptures

  test "book ids and names are unique across volumes" do
    books = Scriptures.books()
    assert books |> Enum.map(& &1.id) |> Enum.uniq() |> length() == length(books)
    assert books |> Enum.map(& &1.name) |> Enum.uniq() |> length() == length(books)
  end

  test "every volume's name index points only at its own books" do
    indexes =
      for volume <- Scriptures.volumes(), {name, _} <- volume.__volume__().name_index, do: name

    duplicated = indexes |> Enum.frequencies() |> Enum.filter(fn {_, n} -> n > 1 end)

    assert duplicated == [],
           "names/aliases shared by more than one volume: #{inspect(duplicated)}"
  end

  test "lookup routes by book and reports unknown books" do
    assert {:ok, [%{volume: :book_of_mormon}]} = Scriptures.lookup("Moroni 10:4")
    assert {:error, :book_not_found} = Scriptures.lookup("Hezekiah 1:1")
    assert {:error, :verse_not_found} = Scriptures.lookup("Moroni 10:99")
  end

  test "search across volumes" do
    assert [_, _, _] = Scriptures.search("and it came to pass", limit: 3)

    assert [%{reference: "2 Nephi 2:25"}] =
             Scriptures.search("adam fell", volume: :book_of_mormon)

    assert [%{reference: "2 Nephi 2:25"}] = Scriptures.search("adam fell", book: "2 Ne.")
  end
end

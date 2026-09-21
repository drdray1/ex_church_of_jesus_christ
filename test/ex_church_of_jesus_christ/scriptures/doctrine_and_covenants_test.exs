defmodule ExChurchOfJesusChrist.Scriptures.DoctrineAndCovenantsTest do
  use ExUnit.Case, async: true

  alias ExChurchOfJesusChrist.Scriptures.DoctrineAndCovenants

  doctest DoctrineAndCovenants

  # Verses per section in the current edition, sections 1-138.
  @verse_counts [39, 3, 20, 7, 35, 37, 8, 12, 14, 70, 30, 9, 1, 11, 6, 6, 9, 47, 41, 84] ++
                  [12, 4, 7, 19, 16, 2, 18, 16, 50, 11, 13, 5, 18, 12, 27, 8, 4, 42, 24, 3] ++
                  [12, 93, 35, 6, 75, 33, 4, 6, 28, 46, 20, 44, 7, 10, 6, 20, 16, 65, 24, 17] ++
                  [39, 9, 66, 43, 6, 13, 14, 35, 8, 18, 11, 26, 6, 7, 36, 119, 15, 22, 4, 5] ++
                  [7, 24, 6, 120, 12, 11, 8, 141, 21, 37, 6, 2, 53, 17, 17, 9, 28, 48, 8, 17] ++
                  [101, 34, 40, 86, 41, 8, 100, 8, 80, 16, 11, 34, 10, 2, 19, 1, 16, 6, 7, 1] ++
                  [46, 9, 17, 145, 4, 3, 12, 25, 9, 23, 8, 66, 74, 12, 7, 42, 10, 60]

  test "has all 138 sections with the current edition's verse counts" do
    {:ok, sections} = DoctrineAndCovenants.chapters(:doctrine_and_covenants)
    assert Enum.map(sections, & &1.number) == Enum.to_list(1..138)
    assert Enum.map(sections, &length(&1.verses)) == @verse_counts
    assert DoctrineAndCovenants.verse_count() == 3654

    for %{verses: verses} <- sections do
      assert Enum.map(verses, & &1.number) == Enum.to_list(1..length(verses))
      assert Enum.all?(verses, &(String.length(&1.text) > 5))
      # Some verses quote the Bible ("Revelation 20:12"), so only check for
      # verse numbers left at the start of a verse.
      refute Enum.any?(verses, &Regex.match?(~r/^\d/, &1.text))
    end
  end

  test "first and last verses" do
    assert DoctrineAndCovenants.verse!("D&C", 1, 1).text =~ ~r/^Hearken, O ye people of my church/
    assert DoctrineAndCovenants.verse!("D&C", 138, 60).text =~ ~r/Jesus Christ, even so\. Amen\.$/
  end

  test "reference forms" do
    for ref <- [
          "D&C 89:18",
          "d&c 89:18",
          "DC 89:18",
          "Doctrine and Covenants 89:18",
          "D and C 89:18"
        ] do
      assert {:ok, [%{reference: "Doctrine and Covenants 89:18"}]} =
               DoctrineAndCovenants.lookup(ref)
    end

    assert {:error, :chapter_not_found} = DoctrineAndCovenants.lookup("D&C 139:1")
  end
end

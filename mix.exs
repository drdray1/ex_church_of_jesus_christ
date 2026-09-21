defmodule ExChurchOfJesusChrist.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ex_church_of_jesus_christ,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "The scriptures of The Church of Jesus Christ of Latter-day Saints as Elixir data. " <>
          "Contains all five standard works: the Old and New Testaments (KJV), the Book of Mormon, the Doctrine and Covenants and the Pearl of Great Price.",
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"Scriptures" => "https://www.churchofjesuschrist.org/study/scriptures?lang=eng"},
      files: ~w(lib mix.exs README.md LICENSE .formatter.exs)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md"],
      groups_for_modules: [
        Structs: [
          ExChurchOfJesusChrist.Scriptures.Book,
          ExChurchOfJesusChrist.Scriptures.Chapter,
          ExChurchOfJesusChrist.Scriptures.Verse
        ]
      ]
    ]
  end
end

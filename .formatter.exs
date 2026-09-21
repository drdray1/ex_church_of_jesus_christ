# Used by "mix format"
[
  inputs:
    Enum.flat_map(
      ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
      &Path.wildcard(&1, match_dot: true)
    ) -- Path.wildcard("lib/ex_church_of_jesus_christ/scriptures/book_of_mormon/data/*.ex")
]

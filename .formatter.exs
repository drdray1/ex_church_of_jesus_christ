# Used by "mix format". Generated data modules (scripts/generate_volume.py) are excluded.
[
  inputs:
    Enum.flat_map(
      ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
      &Path.wildcard(&1, match_dot: true)
    ) --
      (Path.wildcard("lib/ex_church_of_jesus_christ/scriptures/*/data.ex") ++
         Path.wildcard("lib/ex_church_of_jesus_christ/scriptures/*/data/*.ex"))
]

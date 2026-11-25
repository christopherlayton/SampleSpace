# Typo Patrol

The Crew Log was typed by people, and it shows. Before you count anything by category, **list the categories**:

```r
sort(unique(astronauts$nationality))
```

Scan the list and you'll find "Hungry" (Hungary), "Malysia" (Malaysia) and "Netherland" (the Netherlands). The occupation column records the same job as "pilot" and "Pilot", and "flight engineer" and "Flight engineer". R treats every spelling as a different category.

## Recoding with `case_when()`

`case_when()` checks conditions in order and uses the value after `~` for the first one that's true. `.default` says what to use when none is:

```r
astronauts |>
  mutate(nationality = case_when(
    nationality == "Hungry" ~ "Hungary",
    nationality == "Malysia" ~ "Malaysia",
    .default = nationality
  ))
```

For one yes/no condition, `if_else(condition, yes, no)` is shorter.

Capitals are easier: `tolower()` makes all text lower case (`toupper()` the opposite), so "Pilot" and "pilot" become the same.

`n_distinct(x)` counts the different values in `x`, which is a quick before-and-after check.

> **Coming from SPSS?** This is *Transform → Recode into Same Variables*, with the old → new values written out. Writing them in code means your recoding decisions are documented, which is exactly what a methods section and a committee will ask about.

> **Keep the raw data raw.** Never fix typos by editing the CSV by hand. Fix them in code, so anyone can see what changed and rerun it on the original file.

## Mission

1. Load readr and dplyr and import `astronauts.csv` into `astronauts`.
2. Store a cleaned copy in `clean`, with the three nationality typos fixed (Hungary, Malaysia, Netherlands) and `occupation` in lower case.
3. Store the number of different occupation spellings **before** cleaning in `n_jobs_raw`, and **after** in `n_jobs_clean`.

# Course Correction

Two more verbs, and one helper.

| Verb | Does | Example |
|---|---|---|
| `mutate()` | adds or changes **columns** | `mutate(days = hours_mission / 24)` |
| `arrange()` | **sorts** rows | `arrange(year_of_mission)` |
| `slice_head(n = 5)` | keeps the first *n* rows | |

`arrange()` sorts from smallest to largest; wrap a column in `desc()` to sort largest first. Sort by a second column to break ties: `arrange(desc(days), name)`.

`mutate()` can make several columns at once, and a new column can use one made earlier in the same call:

```r
astronauts |>
  mutate(days = hours_mission / 24,
         weeks = days / 7)
```

> **Coming from SPSS?** `mutate()` is *Transform → Compute Variable*, and `arrange()` is *Data → Sort Cases*. In SPSS each step changes the open dataset; in R you decide whether to overwrite (`astronauts <- astronauts |> mutate(...)`) or keep the result under a new name.

> **From the Crew Log:** the log has no ages, only years. `year_of_mission - year_of_birth` is an approximate age (off by one for anyone whose birthday came later in the year). Say so whenever you report it.

## Mission

1. Load readr and dplyr and import `astronauts.csv` into `astronauts`.
2. Store `astronauts` with two new columns in `missions`: `days` (mission length in days) and `age_at_mission` (year of mission minus year of birth).
3. Store the **five longest missions** in `longest`: sorted longest first, with only `name`, `year_of_mission` and `days`.
4. Store the oldest age at a mission in `oldest_age`.

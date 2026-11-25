# Fleet Summary

Most descriptive tables in a dissertation are **one row per group**: means by condition, counts by category. In dplyr that's two verbs working together:

```r
astronauts |>
  group_by(military_civilian) |>
  summarise(missions = n(),
            mean_hours = mean(hours_mission))
```

- `group_by()` marks the groups. It doesn't change the rows you see.
- `summarise()` collapses each group to **one row**, with one column per summary you ask for.
- `n()` counts the rows in each group.

Counting categories is so common that it has a shortcut: `count(nationality)` is the same as `group_by(nationality) |> summarise(n = n())`. Add `sort = TRUE` to put the biggest group first.

> **From the Crew Log:** remember what a row is. Every row here is a *mission*, so `count(nationality)` on the whole log counts **missions** per nation, not astronauts. Frequent flyers get counted several times. Keep one row per person (their first mission) when you want to count people.

> **Coming from SPSS?** `group_by() |> summarise()` covers *Analyze → Compare Means → Means* and *Data → Aggregate*. `count()` is a one-variable *Frequencies* table without the percentages.

## Mission

1. Load readr and dplyr and import `astronauts.csv` into `astronauts`.
2. Store a summary by `sex` in `by_sex`, with a column `missions` (the number of missions) and `median_hours` (the median mission length).
3. Store the number of **astronauts** (not missions) per nationality in `nation_counts`, largest first, using `count()`.
4. Store the nationality with the most astronauts in `top_nation`.

# Crew Roster

The last job in Wrangler's Reach: turn the mission log (one row per mission) into a **roster** with one row per astronaut. That's the layout you need whenever the question is about *people*, and it's what the next sectors analyse.

{{spss}}

## Aggregate in R

SPSS's *Aggregate* is `group_by()` plus `summarise()`. The **Break variable** becomes the `group_by()`, and each summary becomes a column:

```r
roster <- clean |>
  group_by(number) |>
  summarise(name = first(name),
            missions = n(),
            total_hours = sum(hours_mission))
```

`first()` takes the value from a person's first row, like SPSS's `FIRST()`. Use it for things that don't change from mission to mission, such as name or sex. Columns you don't mention in `summarise()` are dropped.

SPSS's `COMPUTE spacewalker = eva_hours > 0` makes a 0/1 variable. In R, `roster$eva_hours > 0` is `TRUE`/`FALSE`, and `sum()` counts the `TRUE`s.

> **Data detective:** `number` is the source's astronaut ID, but in this log one ID (385) is shared by two people, Yuri Baturin and Pedro Duque, who both first flew in 1998. Grouping by ID gives 564 rows, as in the published database, while there are really 565 people. Always check that your ID really identifies one person: `astronauts |> group_by(number) |> summarise(k = n_distinct(name)) |> filter(k > 1)`. Here we follow the source's IDs and note the problem, which is what you'd do in a methods section.

## Mission

1. Load readr and dplyr, import `astronauts.csv` into `astronauts`, and store a copy with the three nationality typos fixed (Hungary, Malaysia, Netherlands) in `clean`.
2. Store one row per astronaut in `roster`, grouped by `number`, with `name`, `sex`, `nationality`, `missions`, `total_hours` and `eva_hours` as in the SPSS dialog.
3. Store the number of astronauts who made at least one spacewalk in `n_spacewalkers`.
4. Store the percentage of astronauts who made a spacewalk, rounded to 1 decimal, in `pct_spacewalkers`.

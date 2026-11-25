# Pipe Forecast

Time to test your feel for dplyr. Each question uses this small data frame, `crew`, which is already loaded (with dplyr):

| name | team | score |
|---|---|---|
| Ada | A | 7 |
| Ben | B | 3 |
| Cai | A | 9 |
| Dee | B | 5 |

Two new pieces appear in the questions:

- `pull(col)` hands back a single column as a **vector**, so it prints like `[1] ...` rather than as a table.
- `group_by(team)` splits the rows into groups, and `summarise()` then returns **one row per group**. You'll use this pair constantly in the next level.

> **Tip:** when a pipeline confuses you, run it one step at a time: highlight up to (not including) a `|>` and run that part.

## Mission

Five predictions on the right. Lock in your guess; once you're right, R runs the code so you can compare.

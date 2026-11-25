# Pandas Pipelines

The dplyr verbs you learned in Wrangler's Reach all have pandas versions. The pattern is the same: a data frame goes in, a new one comes out.

| dplyr | pandas |
|---|---|
| `filter(log, mission_number == 1)` | `log[log["mission_number"] == 1]` or `log.query("mission_number == 1")` |
| `mutate(first, age = ...)` | `first.assign(age=...)` |
| `select(first, name, age)` | `first[["name", "age"]]` |
| `arrange(first, desc(age))` | `first.sort_values("age", ascending=False)` |
| `slice_head(n = 3)` | `.head(3)` |
| `count(first, nationality, sort = TRUE)` | `first["nationality"].value_counts()` |
| `group_by(sex) \|> summarise(n = n(), m = mean(age))` | `first.groupby("sex")["age"].agg(["count", "mean"])` |

Methods chain with dots the way `|>` chains verbs. Wrap a long chain in parentheses to split it over lines:

```python
oldest = (first
          .sort_values("age", ascending=False)
          .head(3)[["name", "age"]])
```

> Inside the brackets, `log["mission_number"] == 1` is a column of `True`/`False`, one per row; pandas keeps the rows that are `True`. Use `&` (and) and `|` (or) to combine conditions, each in its own parentheses.

{{twin}}

## Mission

`log` is loaded (pandas is imported as `pd`).

1. Keep each astronaut's **first** mission in `first`, and add `age` (year of mission − year of birth) with `assign()`.
2. Store first-time flyers per nationality, most first, in `by_nation`, and the top nationality's name in `top_nation`.
3. Store the `count` and `mean` age by `sex` in `ages`.
4. Store the three oldest first-time flyers' `name` and `age` in `oldest`.

# Crew Bars

Bar charts show **counts** of categories. `geom_bar()` does the counting itself: give it a category on `x` and it draws one bar per category, as tall as the number of rows.

```r
ggplot(first_flights, aes(x = factor(decade))) +
  geom_bar()
```

## A second category

Map another variable to `fill` and each bar is split. `position` decides how:

| `position` | Shows | Good for |
|---|---|---|
| `"stack"` (default) | counts, stacked | totals and parts together |
| `"dodge"` | counts, side by side | comparing counts between groups |
| `"fill"` | each bar stretched to 100% | comparing **proportions** when group sizes differ |

When totals differ a lot (44 first-time flyers in the 1960s, 167 in the 1990s), a stacked bar makes it hard to compare shares; `position = "fill"` fixes that.

`geom_bar()` counts rows; `geom_col()` draws bars of a height you already computed (next level).

> **From the Crew Log:** count *people* here, so use first flights only. Counting missions would weight frequent flyers several times.

## Mission

1. Load the packages, import `astronauts.csv`, and store each astronaut's first mission, with a `decade` column, in `first_flights`.
2. Store a bar chart of first-time flyers per decade, filled by `sex`, in `p_count`, and draw it.
3. Store the same chart showing the **proportion** of women and men in each decade in `p_share`, and draw it.
4. Store a table with one row per decade and columns `decade`, `flyers` and `women` in `women_by_decade`.

# Scatter Field

A scatterplot shows how two numeric variables move together: one point per row, `x` against `y`.

```r
ggplot(missions, aes(x = year_of_mission, y = age_at_mission)) +
  geom_point()
```

## Overplotting

With 1,277 missions and whole-number years and ages, many points land on exactly the same spot. You can't see 20 points stacked in one place. Two fixes:

- `alpha = 0.3` makes each point 30% opaque, so crowded spots look darker.
- `geom_jitter(width = 0.3, height = 0.3)` nudges points randomly by a small amount. Say so in the caption if you use it.

## Colour and trend

Map a third variable to `colour` to compare groups in one plot. `geom_smooth(method = "lm")` adds a straight line of best fit with a shaded confidence band. (You'll learn what that line is in the Relationship Ring; for now it's a visual guide.) Because `colour = sex` is mapped in `ggplot()`, every layer uses it, so you get one line per group.

> **From the Crew Log:** ages are approximate (year minus year), so each "age" is within a year of the truth. That's another reason the points line up in rows.

## Mission

1. Load the packages, import `astronauts.csv`, and store it with `age_at_mission` (year of mission minus year of birth) in `missions`.
2. Store a scatterplot of `age_at_mission` (y) against `year_of_mission` (x) in `p_scatter`, with points 30% opaque (`alpha = 0.3`), and draw it.
3. Store a version in `p_trend` that also colours points by `sex` and adds a straight trend line (`method = "lm"`) for each sex, and draw it.

What's happened to the age of astronauts over six decades?

# Military or Civilian?

The question from your arrival at the Means Cluster: **do military and civilian astronauts fly missions of different lengths?**

## One row per person

The log has one row per *mission*, and most astronauts flew more than once. A *t*-test on the rows would count frequent flyers several times and treat their missions as independent people, which they aren't. So first make **one row per astronaut**: each person's average mission length, with their military/civilian status.

```r
people <- astronauts |>
  group_by(number) |>
  summarise(military_civilian = first(military_civilian),
            mean_hours = mean(hours_mission))
```

## Then the full workflow

1. **Describe** each group: *n*, *M*, *SD*, and the median, because mission length is badly skewed.
2. **Check** equal variances with Levene's test. With hundreds of people per group, the Central Limit Theorem takes care of normality for the *means*, but look at the medians alongside.
3. **Test** with Welch's *t*.
4. **Size** the difference with Cohen's *d*, whatever the *p*.

- **H₀:** μ(military) = μ(civilian), mean mission length per astronaut
- **H₁:** μ(military) ≠ μ(civilian)

## Mission

`astronauts` is loaded, with readr, dplyr, car and effectsize.

1. Make `people`: one row per astronaut `number`, with `military_civilian` and `mean_hours`.
2. Store each group's `n`, `mean`, `sd` and `median` of `mean_hours` in `group_stats`.
3. Store SPSS's Levene test in `levene`, Welch's *t*-test in `welch` and Cohen's *d* in `d`.
4. Store your decision at α = .05 in `decision`: `"reject"` or `"fail to reject"`.

Then read your results. Is the difference big enough to matter, whatever the test says?

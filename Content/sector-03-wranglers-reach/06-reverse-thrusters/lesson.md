# Reverse Thrusters

Most questionnaires mix positively and negatively worded items, so that people who agree with everything stand out. `crew_morale.csv` holds a six-item morale scale (1 = strongly disagree … 5 = strongly agree) from 48 crew members on two programmes:

| Item | Wording |
|---|---|
| m1 | I look forward to each shift. |
| m2 | I feel worn down by the work. *(negative)* |
| m3 | My team supports me. |
| m4 | I'm proud of what we achieve. |
| m5 | I often think about leaving. *(negative)* |
| m6 | I'd recommend this posting to a friend. |

Before averaging, the negative items must be **reverse-scored**, so that a high number always means high morale. On a scale from 1 to *k*, the reversed score is **(k + 1) − x**; for 1–5 that's `6 - x` (5 ↔ 1, 4 ↔ 2, 3 stays 3).

A quick check that you've found the right items: a negative item correlates **negatively** with the others. After reversing, the sign flips.

## A composite score

`rowMeans()` averages across columns, one result per row. Inside `mutate()`, `pick()` chooses the columns:

```r
morale |>
  mutate(morale_score = rowMeans(pick(m1, m2_r, m3, m4, m5_r, m6), na.rm = TRUE))
```

With `na.rm = TRUE` a person who skipped an item still gets the mean of the items they answered. That's the usual choice when only a few items are missing; Missing Cargo, next, looks at the alternatives.

> **Coming from SPSS?** This is *Transform → Recode into Different Variables* (1→5, 2→4, …) and then *Compute Variable* with `MEAN(m1, m2_r, ...)`. SPSS's `MEAN()` also uses whichever items are answered, so `na.rm = TRUE` matches it.

> **APA note:** report the scale's reliability (e.g., Cronbach's α, from `psych::alpha()`) and say which items were reverse-scored.

## Mission

1. Load readr and dplyr and import `crew_morale.csv` into `morale`.
2. Store the correlation between `m1` and `m2` in `r_before` (use `use = "complete.obs"`).
3. Add reversed items `m2_r` and `m5_r` to `morale`.
4. Store the correlation between `m1` and `m2_r` in `r_after`.
5. Add `morale_score`, the mean of the six items (reversed versions of m2 and m5) using the items each person answered, and store its overall mean in `mean_morale`.

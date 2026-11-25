# Factor Forge

A **factor** is R's type for a categorical variable: a fixed set of categories called **levels**.

```r
group <- c("b", "a", "b", "c")
group_f <- factor(group)
group_f
#> [1] b a b c
#> Levels: a b c
```

Why not just keep text? Factors know every possible category (even ones with no cases yet), they keep categories in a meaningful order, and statistical functions (`t.test()`, `aov()`, `lm()`) use them to set up group comparisons.

## Level order matters

By default levels are sorted alphabetically. Set your own order with `levels =`:

```r
factor(group, levels = c("c", "a", "b"))
```

The **first level is the reference group** in models such as regression and ANOVA contrasts, so a control condition usually goes first.

## Counting categories

| Code | Gives |
|---|---|
| `levels(f)` | the category names, in order |
| `nlevels(f)` | how many categories |
| `table(f)` | a frequency table: how many cases in each |

> **Coming from SPSS?** In SPSS a categorical variable is usually numbers with *Value Labels* (1 = control, 2 = treatment). A factor keeps the codes and labels together, so you never need a codebook to read your output.

## Mission

`condition` records which arm of a study each of seven participants was in.

1. Make `condition_f`, a factor with the levels in this order: **control, waitlist, treatment**.
2. Store the number of levels in `n_conditions`.
3. Store the frequency table of `condition_f` in `condition_counts`.

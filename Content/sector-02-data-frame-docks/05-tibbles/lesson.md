# Tibble Transfer

The **tidyverse** (the packages you'll use for wrangling and plotting) works with **tibbles**: data frames with better manners. A tibble *is* a data frame, so everything you've learned still works, plus:

- printing shows only the first 10 rows and the columns that fit, with each column's type (`<chr>`, `<dbl>`, `<int>`, `<fct>`);
- it never quietly changes your data: text stays text, names stay exactly as you wrote them;
- `df$sco` won't partially match `score`; it warns instead of guessing.

## Using a package

Tibbles come from the `tibble` package. A package is installed once, but you **load** it in every script with `library()`:

```r
library(tibble)
```

| Code | Does |
|---|---|
| `as_tibble(df)` | converts a data frame to a tibble |
| `tibble(a = ..., b = ...)` | builds one; later columns can use earlier ones |
| `glimpse(df)` | one line per variable: type and first values, good for wide data |

`read_csv()`, which you'll use next, gives you a tibble straight away.

> **Coming from SPSS?** Packages are like SPSS modules or extension bundles, except free and numbering in the thousands. `library()` switches one on for this session.

## Mission

1. Load the `tibble` package.
2. Convert `study` to a tibble called `study_tbl` and look at it with `glimpse()`.
3. Build a tibble called `pilot` with columns `id` (1 to 4), `score` (38, 45, 29, 41, out of 50) and `score_pct` (score as a percentage), using `tibble()`.

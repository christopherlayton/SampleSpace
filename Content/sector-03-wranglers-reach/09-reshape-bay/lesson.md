# Reshape Bay

The morale survey is wide: one row per crew member, one column per item. To summarise **each item** with `group_by()`, turn the items into rows.

## `pivot_longer()`

```r
library(tidyr)
morale_long <- morale |>
  pivot_longer(m1:m6, names_to = "item", values_to = "rating")
```

- The first argument picks the columns to stack (`m1:m6` means "m1 through m6").
- `names_to` names the new column that holds the old column *names* (m1, m2, …).
- `values_to` names the new column that holds the *values*.

Columns you don't pick (`id`, `programme`, `sleep_hours`) are copied onto every new row.

## `pivot_wider()`

The reverse: one new column per value of `names_from`, filled from `values_from`.

```r
morale_long |>
  pivot_wider(names_from = item, values_from = rating)
```

> **Item analysis:** before building a scale score, look at each item's mean and missing count. An item that almost everyone skips, or that everyone answers the same way, tells you something about the questionnaire.

## Mission

1. Load readr, dplyr and tidyr and import `crew_morale.csv` into `morale`.
2. Store the six items in long format in `morale_long`, with columns `item` and `rating`.
3. Store one row per item in `item_summary`, with `mean_rating` (ignoring missing answers) and `n_missing`.
4. Store the item with the lowest mean in `lowest_item`.
5. Pivot `morale_long` back to wide and store it in `morale_wide`.

Before you answer step 4, think: which items would you *expect* to score lowest, before reverse-scoring?

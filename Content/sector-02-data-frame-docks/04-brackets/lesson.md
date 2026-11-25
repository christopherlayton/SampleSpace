# Row and Column

Square brackets on a data frame take **two** positions, separated by a comma: `df[rows, columns]`. Leave one side empty to mean "all":

| Code | Gives |
|---|---|
| `study[3, ]` | row 3, every column |
| `study[, "score"]` | every row of `score` (a vector) |
| `study[1:5, c("id", "score")]` | rows 1–5, two columns |
| `study[study$age >= 25, ]` | rows where the condition is TRUE |

Forgetting the comma is the most common slip: `study[3]` gives the 3rd **column**, not the 3rd row.

## Selecting cases by condition

The row position can be a logical vector, exactly like filtering a vector in Logic Gates. `study$condition == "treatment"` is TRUE for treatment rows, so:

```r
study[study$condition == "treatment", ]
```

keeps only the treatment group. Use `==` to compare. A single `=` sets an argument, and R will complain.

You'll meet a friendlier way to do this (`dplyr::filter()`) in Wrangler's Reach. Brackets are still worth knowing: you'll see them in other people's code and in help pages.

> **Coming from SPSS?** `study[study$condition == "treatment", ]` is *Select Cases → If*, but it makes a new data frame and leaves `study` complete. No forgetting to turn the filter off.

## Mission

`study` (12 participants) is loaded.

1. Store row 3 in `row_three`.
2. Store the `score` column, using brackets, in `all_scores`.
3. Store only the treatment-group rows in `treatment_only`.
4. Store the `id` and `score` columns for participants aged **25 or over** in `older_scores`.

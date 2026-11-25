# The Long Tail

Sector review. The ship's computer asked how long a typical mission is. Time to answer properly: the centre, the spread, the record, and one sentence a journal would accept.

## Numbers into sentences

`sprintf()` fills placeholders in text with values. `%.0f` means "a number with 0 decimals", `%.2f` two decimals, `%d` a whole number, `%s` text:

```r
sprintf("M = %.2f, SD = %.2f", 26.86, 6.537)
#> [1] "M = 26.86, SD = 6.54"
```

Writing results sentences with `sprintf()` (or, later, inline code in Quarto) means the numbers in your text can't drift from the numbers in your analysis.

## The record holder

`slice_max(col, n = 1)` keeps the row with the largest value of `col` (`slice_min()` the smallest). Unlike `max()`, you get the whole row, name included.

> **APA note:** for a skewed variable, report the median and IQR and say that the distribution was skewed. APA style italicises statistical symbols (*M*, *SD*, *Mdn*); in plain text you can't, so the sentence here leaves them plain.

## Mission

1. Load readr and dplyr and import `astronauts.csv` into `astronauts`.
2. Store a one-row summary in `centre` with columns `mean_hours`, `median_hours`, `sd_hours` and `iqr_hours`.
3. Store the longest mission in `longest`, with only `name`, `year_of_mission` and `hours_mission`.
4. Store this sentence in `apa`, with every number from `centre` rounded to 0 decimals:

`Mission length was positively skewed (Mdn = 261 h, IQR = 192 h; M = 1051 h, SD = 1715 h).`

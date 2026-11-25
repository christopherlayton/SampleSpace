# SPSS Signal

Your existing data are probably in SPSS `.sav` files. The **haven** package reads them, value labels and all:

```r
library(haven)
teach <- read_sav("teaching_study.sav")
```

## Labelled columns

SPSS stores categories as numbers plus *value labels*. haven keeps both, in a **labelled** column. Printing shows the code and its label:

```r
teach$method
#> <labelled<double>[30]>: Teaching method
#>  [1] 1 1 1 2 2 ...
#> Labels:
#>  value           label
#>      1         Lecture
#>      2 Active learning
```

The `Teaching method` at the top is the SPSS *variable label*.

To analyse a labelled column as categories, convert it to a factor with **`as_factor()`** (haven's version, with an underscore). The labels become the factor levels:

```r
table(as_factor(teach$method))
```

Numeric variables without value labels, like an exam score, arrive as plain numbers and work as usual.

> **Coming from SPSS?** You don't have to give up your `.sav` files or redo any coding. `read_sav()` brings across variable labels, value labels and declared missing values. (`write_sav()` goes the other way, if a co-author still needs SPSS.)

## Mission

`teaching_study.sav` holds a study comparing two teaching methods: 30 students, their method, gender, final exam score (%), and exam anxiety.

1. Load haven and import the file into `teach`.
2. Store the number of students in `n_students`.
3. Store the mean exam score in `mean_score`.
4. Store a frequency table of teaching method **by label** in `method_counts` (use `as_factor()`).

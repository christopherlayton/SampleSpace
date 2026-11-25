# Standard Error Translator

Your committee member ticked **S.E. mean** in SPSS's Descriptives dialog. Match their column in R.

{{spss}}

## Reading the table

The **Std. Error** under *Mean* is the standard error of the mean: SD / √*n*. It estimates how far this sample's mean is likely to be from the population mean, the spread you watched the Sampling Machine build. Here *n* is the number of people with a value on that variable: 40 for the pre-test, 37 for the post-test, because three students missed it.

| | Describes | Shrinks with more people? |
|---|---|---|
| **SD** | how spread out the scores are | No: it settles near σ |
| **SE** | how precisely the mean is estimated | Yes, with √*n* |

## A function of your own

Base R has no `se()` function, so write one. A function you'll reuse is better than retyping a formula:

```r
se_mean <- function(x) sd(x, na.rm = TRUE) / sqrt(sum(!is.na(x)))
```

`sum(!is.na(x))` counts the values that aren't missing. `length(x)` would count the NAs too and give a standard error that's too small.

> **Shortcut:** `psych::describe()` already has an `se` column, computed the same way.

> **APA note:** an SE describes precision, not spread. Describe your sample with *M* and *SD*; when you show error bars or a ± value, say whether it's the SD, the SE or a 95% CI.

## Mission

1. Import `wellbeing_survey.csv` into `survey`.
2. Write a function `se_mean(x)` that returns the standard error of the mean, ignoring missing values.
3. Store the standard errors of `anxiety_pre` and `anxiety_post` in `se_pre` and `se_post`.

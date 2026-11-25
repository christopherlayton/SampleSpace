# Descriptives Translator

Your committee member uses SPSS and wants to check your numbers. Here's their output for the wellbeing survey. Match it in R.

{{spss}}

## Reading the table

- **N** differs by row: SPSS's Descriptives leaves out missing values one variable at a time, like `describe()`.
- **Valid N (listwise)** is the number of people with *no* missing value on any of the three variables, which matters if you later analyse them together.
- **Skewness** and **Kurtosis** each come with a **Std. Error**. A rough check some textbooks use: a statistic more than about twice its standard error suggests real non-normality. With large samples that test flags trivial departures, so look at a plot too.

## Matching SPSS in R

psych's `describe()` uses a different skewness/kurtosis formula from SPSS by default. Ask for SPSS's with `type = 2`:

```r
describe(survey[, c("age", "anxiety_pre", "anxiety_post")], type = 2)
```

`describe()` doesn't report the standard errors of skew and kurtosis; SPSS's come from formulas based on *n* alone.

> **Rounding:** SPSS rounds a half up (29.625 → 29.63). R's printing may show 29.62, because R rounds to even and because 29.625 is stored as a binary fraction. The stored number is the same.

## Mission

1. Load readr and psych and import `wellbeing_survey.csv` into `survey`.
2. Store `describe()` of `age`, `anxiety_pre` and `anxiety_post` with SPSS's formulas in `desc`.
3. Store the skewness of `anxiety_post` in `skew_post` and the kurtosis of `age` in `kurt_age`.
4. Store SPSS's Valid N (listwise) in `n_listwise`.

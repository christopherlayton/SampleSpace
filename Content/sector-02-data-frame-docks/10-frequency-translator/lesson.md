# Frequency Translator

This is an **SPSS Translate** level: below is what SPSS shows for an analysis of `teaching_study.sav`. Your job is to get the same numbers in R.

{{spss}}

## Reading the SPSS table

A Frequencies table has two percentage columns, and they answer different questions:

- **Percent** divides by *every* case in the file (30), including the two students whose anxiety answer was "No answer".
- **Valid Percent** divides by the cases that *have* a value (28). This is the one you usually report.
- **Cumulative Percent** adds up Valid Percent row by row (useful for ordinal items: "50% were moderately anxious or less").

## The same in R

```r
counts <- table(teach_f$anxiety)       # Frequency
100 * counts / nrow(teach_f)           # Percent (of all 30)
100 * prop.table(counts)               # Valid Percent (of the 28 answered)
```

`table()` leaves out `NA` by default, so `prop.table()` divides by the answered cases, exactly like Valid Percent. Wrap results in `round(x, 1)` to match SPSS's one decimal place.

Because "No answer" is still one of the factor's levels, `table()` lists it with a count of 0. That doesn't change any of the percentages. If you'd rather not see it, `droplevels()` removes levels that have no cases.

> **APA note:** report percentages of the valid cases and say how many were missing, e.g. "Of the 28 students who answered, 28.6% were *very* anxious (2 did not answer)."

## Mission

1. Load haven, import `teaching_study.sav` into `teach`, and convert it with `as_factor()` into `teach_f`.
2. Store the Frequency column for teaching method in `method_counts`.
3. Store the number of missing anxiety answers in `n_missing`.
4. Store the **Percent** column for anxiety, rounded to 1 decimal, in `anxiety_pct`.
5. Store the **Valid Percent** column for anxiety, rounded to 1 decimal, in `anxiety_valid`.

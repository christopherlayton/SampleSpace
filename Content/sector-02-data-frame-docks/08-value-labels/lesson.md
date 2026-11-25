# Decoding Labels

`as_factor()` also works on a **whole data frame**: every column with value labels becomes a factor and the rest are left alone.

```r
teach_f <- as_factor(teach)
```

After that you work with words, not codes: `teach_f$method == "Active learning"`.

Keep both versions while you're learning: `teach` with the numeric codes, `teach_f` with labels.

## Missing-value codes from SPSS

SPSS datasets often use a code such as `9` or `99` for "No answer", declared under *Missing* in Variable View. If R treated `9` as a real answer, a 1–5 anxiety mean would be inflated.

By default `read_sav()` converts **declared** missing codes to `NA`, so they're excluded once you add `na.rm = TRUE`. If you need to know *why* a value is missing (refused vs. not applicable), import with `read_sav(file, user_na = TRUE)` to keep the codes.

**But:** a code that was never declared missing in SPSS (someone typed 99 and forgot Variable View) comes through as a real number. Always check ranges with `summary()` after importing.

> **APA note:** describe how much data was missing and how you handled it (e.g., "Two participants did not answer the anxiety item and were excluded from analyses of that variable").

## Mission

1. Load haven and import `teaching_study.sav` into `teach`.
2. Convert the whole data frame to factors and store it in `teach_f`.
3. Store how many students had **Active learning** in `n_active`, using `teach_f`.
4. Store how many anxiety answers are missing (they were "No answer" in SPSS) in `n_no_answer`.
5. Store the mean anxiety code (1–5) of those who answered in `mean_anxiety`, using `teach`.

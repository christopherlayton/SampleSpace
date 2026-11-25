# Signal Decoder

Data from online survey tools often arrive as **text**, even when the answers are numbers. You convert them with the `as.` family:

| Function | Converts to |
|---|---|
| `as.numeric()` | numbers |
| `as.character()` | text |
| `as.logical()` | `TRUE`/`FALSE` |
| `as.integer()` | whole numbers |

```r
as.numeric(c("4", "7", "10"))
#> [1]  4  7 10
```

## When conversion fails

Text R can't read as a number becomes `NA` ("not available"), and R warns you:

```r
as.numeric(c("21", "twenty"))
#> [1] 21 NA
#> Warning: NAs introduced by coercion
```

**Don't ignore that warning.** It means some answers were lost in conversion. Always count how many, and look at the original text to see why.

> **Coming from SPSS?** This is like changing a String variable to Numeric in Variable View. SPSS silently turns unreadable values into system-missing; R at least tells you.

## Mission

A survey export gave you `ages_text` and `consent_text` as text.

1. Convert `ages_text` to numbers and store them in `ages`. (Expect a warning!)
2. Count how many ages couldn't be converted and store the count in `n_unreadable`.
3. Convert `consent_text` to logical values and store them in `consent`.
4. Count how many participants consented and store it in `n_consented`.

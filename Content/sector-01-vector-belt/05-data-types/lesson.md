# Type Scanner

Every vector has a **type**, and every value in it shares that type. The three you'll use most:

| Type | Looks like | Use it for |
|---|---|---|
| numeric | `34`, `3.8`, `-1.5` | scores, ages, times |
| character | `"P017"`, `"control"` | IDs, free text, labels |
| logical | `TRUE`, `FALSE` | yes/no answers, conditions |

`class()` tells you what you've got:

```r
class(3.8)
#> [1] "numeric"
class("3.8")
#> [1] "character"
```

The quotes matter: `"3.8"` is text that happens to look like a number, so `mean("3.8")` won't work.

## Coercion: one type per vector

If you mix types in `c()`, R quietly converts (**coerces**) everything to the most flexible type, in this order: logical → numeric → character.

```r
c(1, TRUE)
#> [1] 1 1
```

This is the most common reason a "numeric" column won't average: one stray piece of text (`"n/a"`, `"5 "`, `"seven"`) turns the whole column into character.

> **Coming from SPSS?** SPSS calls these *Numeric* and *String* variables in Variable View. R's logical type has no direct SPSS twin; SPSS would use a 0/1 numeric.

## Mission

1. Store the number **34** in `age`.
2. Store the ID **P017** in `participant_id` as text.
3. Store **TRUE** in `consented`.
4. The starter code makes `mixed` from three different types. Find out what type R made it, with `class()`, and store the answer in `mixed_class`.

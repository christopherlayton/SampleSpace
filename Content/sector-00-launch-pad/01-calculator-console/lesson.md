# Calculator Console

Welcome aboard, Cadet. Your ship's computer speaks **R**, and the simplest way to talk to it is the **console**: you type an expression, R works it out and prints the answer.

```r
2 + 3
#> [1] 5
```

The `[1]` means "this is the first value of the result". In R even a single number is a *vector* (a list of values) that happens to have length one. You'll meet longer vectors in the Vector Belt.

## Arithmetic

| Operator | Meaning | Example | Result |
|---|---|---|---|
| `+` `-` | add, subtract | `10 - 4` | `6` |
| `*` `/` | multiply, divide | `9 / 2` | `4.5` |
| `^` | power | `3 ^ 2` | `9` |
| `sqrt()` | square root | `sqrt(16)` | `4` |

R follows the usual **order of operations**: powers first, then `*` and `/`, then `+` and `-`. Parentheses override that order, so `(1 + 2) * 3` is `9` but `1 + 2 * 3` is `7`.

Anything after a `#` is a **comment**. R ignores it, so use comments to note what your code does.

> **Coming from SPSS?** In SPSS you would click through menus and the result would land in the Output Viewer. In R every step is a line of code, so your whole analysis becomes a script you (or your committee) can rerun exactly.

## Mission

1. Group A has **23** participants and group B has **17**. Write an expression that prints the total sample size, *N*.
2. Three pilots scored **4**, **7** and **10** on a navigation test. Write **one** expression that prints their mean score.

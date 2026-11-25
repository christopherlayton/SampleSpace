# APA Numbers

Three small functions, written once, used in every sentence of your results chapter.

## The helpers

| Function | Gives | Example |
|---|---|---|
| `fmt_num(x, digits = 2)` | `x` with exactly `digits` decimals | `fmt_num(3.1)` → `"3.10"` |
| `fmt_p(p)` | the *p* part of a sentence, with its sign | `fmt_p(0.0321)` → `"= .032"`, `fmt_p(0.00002)` → `"< .001"` |
| `fmt_bounded(x, digits = 2)` | no leading zero, for *r*, *R*², η², *V* | `fmt_bounded(-0.4512)` → `"-.45"` |

`fmt_p()` returns the sign as well as the number, because the sign changes: in a document you write `` *p* `r fmt_p(test$p.value)` `` and get *p* = .032 or *p* < .001.

## Useful pieces

```r
formatC(0.0321, format = "f", digits = 3)   # "0.032"
sub("^0", "", "0.032")                      # ".032"
sub("^(-?)0\\.", "\\1.", "-0.45")           # "-.45": keeps the minus sign
paste("=", ".032")                          # "= .032"
```

`fmt_p()` should build on `fmt_num()` so the rounding rule lives in one place.

## Mission

Write `fmt_num()`, `fmt_p()` and `fmt_bounded()`. The checks try them on numbers you haven't seen, including negatives and a p-value right at .001.

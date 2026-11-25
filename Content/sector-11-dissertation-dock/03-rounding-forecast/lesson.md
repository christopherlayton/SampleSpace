# Rounding Forecast

A results chapter is full of small formatting rules. Getting them right by hand, a few hundred times, is where typos live. Getting them right in code means getting them right once.

## APA number rules you'll code

| Rule | Example |
|---|---|
| Two decimals for means, *SD*s, test statistics and effect sizes | *M* = 3.10, *t*(58) = 2.40, *d* = 0.62 |
| Exact *p* to three decimals (or two) | *p* = .032 |
| *p* below .001 | *p* < .001, never *p* = .000 |
| No leading zero when a value can't exceed 1 (*p*, *r*, *R*², η², *V*) | *r* = .45, *p* = .021 |
| A leading zero when it can (*M*, *SD*, *d*, *t*) | *d* = 0.45 |
| Commas in numbers of 1,000 or more | 1,277 missions |

## round() vs. formatC()

`round()` gives a **number**, which R prints without trailing zeros. `formatC(x, format = "f", digits = 2)` gives **text** with exactly two decimals. Reports need text.

```r
round(0.5000, 2)                        # 0.5
formatC(0.5, format = "f", digits = 2)  # "0.50"
```

Predict each output, then see what R really prints.

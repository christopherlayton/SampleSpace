# Write-up Generator

The last level gave you number formatters. Now put them together: a function that takes a test result and returns the APA fragment, so every test in your chapter is reported the same way.

## What goes in

| Test | APA | From R |
|---|---|---|
| *t*-test | *t*(df) = 2.40, *p* = .019, *d* = 0.62 | `test$parameter`, `test$statistic`, `test$p.value`, plus *d* from `cohens_d()` |
| Correlation | *r*(df) = .45, *p* < .001 | `test$parameter` (*n* − 2), `test$estimate`, `test$p.value` |

Welch's df isn't a whole number. APA reports it as R gives it, to two decimals: *t*(41.73). A Student *t* has a whole-number df: *t*(58).

## Already loaded

```r
fmt_num(3.1)          # "3.10"
fmt_p(0.0321)         # "= .032"     fmt_p(0.00002)  # "< .001"
fmt_bounded(-0.4512)  # "-.45"
fmt_df(41.7311)       # "41.73"      fmt_df(58)      # "58"
```

Use `*t*` and `*p*` for the italics: in a Quarto document the asterisks become italic text.

## Mission

1. Write `apa_t(test, d)`: returns `"*t*(df) = t, *p* ..., *d* = d"` for a `t.test()` result and a Cohen's *d* value.
2. Write `apa_r(test)`: returns `"*r*(df) = r, *p* ..."` for a `cor.test()` result.
3. Try them: store `apa_t()` for the `ToothGrowth` test below in `tooth`, and `apa_r()` for the `mtcars` correlation in `cars`.

The checks run your functions on other tests too, so build everything from `test`, not from typed numbers.

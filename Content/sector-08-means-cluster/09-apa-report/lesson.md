# APA Transmission

Copying numbers from output into a Word document is where typos creep into dissertations. Build the sentence from the R objects instead, and it's right every time the analysis is rerun.

## The target

For an independent-samples *t*-test, APA style wants the group means and SDs, the test, and an effect size:

> Students taught with active learning (*M* = …, *SD* = …) scored higher than students taught by lecture (*M* = …, *SD* = …), *t*(…) = …, *p* …, *d* = ….

- *t* and *d*: two decimals. Here the sentence states the direction in words, so give them as positive numbers (`abs()`).
- *df*: Welch's *df* isn't a whole number, so give two decimals: *t*(25.09).
- *p*: three decimals, no leading zero, and "< .001" for anything smaller.

## A p-value formatter

R has no built-in APA *p*, so write one:

```r
fmt_p <- function(p) {
  if (p < 0.001) "< .001" else paste("=", sub("^0", "", sprintf("%.3f", p)))
}
fmt_p(0.0108)    # "= .011"
fmt_p(0.00002)   # "< .001"
```

`sprintf("%.3f", p)` rounds to three decimals as text ("0.011"), and `sub("^0", "", ...)` removes the leading zero.

## Filling the sentence

`sprintf()` replaces each placeholder, in order: `%.2f` is a number with two decimals and `%s` is text. The template is in your starter code; your job is to hand it the right eight numbers.

> **Plain text vs italics:** R makes plain text, so the italics of *M*, *SD*, *t*, *p* and *d* get added in your document. Quarto (Dissertation Dock) handles that automatically.

## Mission

1. `teach`, `lecture` and `active` are set up for you. Run Welch's *t*-test of `score` by `method` into `res`, and `cohens_d()` into `d`.
2. Write `fmt_p(p)` as above.
3. Fill in the arguments of `sprintf()` so that `apa` is the complete sentence.

# Crosstabs Translator

The teaching study again: did students taught by lecture or by active learning differ in whether they **passed** (a final exam score of 70 or more)? Here is SPSS's Crosstabs output. Match it in R.

{{spss}}

## The Chi-Square Tests table, row by row

| SPSS row | What it is | R |
|---|---|---|
| Pearson Chi-Square | Σ (O − E)² ÷ E | `chisq.test(tab, correct = FALSE)` |
| Continuity Correction | Yates' correction, 2 × 2 only | `chisq.test(tab)` (R's default for 2 × 2) |
| Likelihood Ratio | G² = 2 Σ O ln(O ÷ E) | `2 * sum(tab * log(tab / expected))` |
| Fisher's Exact Test | exact p from the hypergeometric distribution | `fisher.test(tab)` |
| Linear-by-Linear Association | a trend test for ordered categories | rarely needed for 2 × 2 |

Which row to report? With every expected count at least 5 (footnote a), **Pearson's χ²** is the usual choice; with small expected counts, **Fisher's exact test**. The continuity correction is conservative and many statisticians no longer recommend it, but know that it's what `chisq.test()` gives a 2 × 2 table unless you say otherwise.

## Phi and Cramér's V

For a 2 × 2 table, φ and Cramér's V are the same size (φ can be negative; its sign depends on how the categories are coded). effectsize applies a small-sample adjustment by default; `adjust = FALSE` reproduces SPSS.

> **Coming from SPSS?** The *Exact…* button in Crosstabs gives exact tests for bigger tables too. In R, `fisher.test()` handles tables beyond 2 × 2 (use `simulate.p.value = TRUE` if it runs out of memory).

## Mission

`teaching_study.sav` is loaded into `teach` with haven and effectsize, and `method` is a factor.

1. Make `passed` a factor: `"Did not pass"` (score below 70) then `"Passed"`.
2. Store the method × passed counts in `tab`.
3. Store the Pearson test in `pearson`, the continuity-corrected test in `yates` and Fisher's exact test in `fisher`.
4. Store the likelihood-ratio statistic G² in `g2`.
5. Store φ in `phi_value` and Cramér's V in `v`, both unadjusted.

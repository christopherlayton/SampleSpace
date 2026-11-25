# Crew Crosstab

In the Inference Station's Shuffle Test you asked whether the share of women among first-time flyers differed between flights **before 2000** and flights **from 2000 on**, and answered it by shuffling. Era and sex are both categorical, so the classic tool is the **χ² test of independence**.

## From raw columns to a table

`chisq.test()` wants a table of counts, so build one first. Each astronaut counts once, in their first mission's era: independence of observations is the χ² test's one non-negotiable assumption.

```r
crew_table <- table(first$era, first$sex)
prop.table(crew_table, margin = 1)   # row proportions: each era sums to 1
```

Compare **row** percentages when the rows are the groups you're comparing (eras) and the columns the outcome (sex).

## Where is the association?

| Residual | R | SPSS (*Cells…* box) | Read as |
|---|---|---|---|
| Pearson, (O − E) ÷ √E | `$residuals` | Standardized | each cell's share of χ² |
| Adjusted (standardised) | `$stdres` | Adjusted Standardized | roughly a z-score: beyond ±1.96 stands out |

## Cramér's V and the effectsize package

`effectsize::cramers_v()` now applies a small-sample **bias adjustment** by default. SPSS reports the unadjusted value, which is `cramers_v(tab, adjust = FALSE)`, the same as √(χ² ÷ (N(k − 1))).

> **APA note:** give the percentages, then χ²(df, *N* = …) = …, *p* = …, *V* = …. Say whether you used the continuity correction.

## Mission

`astronauts` is loaded with readr, dplyr and effectsize.

1. Make `first`: first missions only, with a factor `era`, levels `"before 2000"` then `"2000 on"`.
2. Store the era × sex counts in `crew_table` and each era's proportions in `row_pct`.
3. Store Pearson's χ² test (no correction) in `test`, and check every expected count is at least 5 in `expected_ok` (`TRUE`/`FALSE`).
4. Store the adjusted residuals in `adj_resid`.
5. Store SPSS's Cramér's V in `v`.

Then compare your p-value with your Shuffle Test result. Should they agree?

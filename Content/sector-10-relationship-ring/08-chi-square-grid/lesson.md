# Chi-square Grid

100 students were taught by lecture or by active learning, and each passed or didn't. Is passing **independent** of the teaching method?

## Observed and expected

If method and passing were independent, each row would split across the columns in the same proportions as the whole sample. Each cell's **expected** count is

**E = row total × column total ÷ N**

and χ² adds up how far the observed counts O are from E:

**χ² = Σ (O − E)² ÷ E**, with (rows − 1)(columns − 1) degrees of freedom.

A cell's **Pearson residual**, (O − E) ÷ √E, shows where the association lives: the red cells hold more than expected, the blue fewer.

## Effect size: Cramér's V

χ² grows with N, so on its own it says nothing about strength. **Cramér's V** = √(χ² ÷ (N × (k − 1))), where k is the smaller of the number of rows and columns, runs from 0 to 1. For a 2 × 2 table it equals |φ|.

## Yates and Fisher

- For **2 × 2** tables, R's `chisq.test()` applies **Yates' continuity correction** by default, which shrinks χ². SPSS prints it as the *Continuity Correction* row; its *Pearson Chi-Square* row is `correct = FALSE`.
- When expected counts are small, `fisher.test()` gives an **exact** p-value, SPSS's *Fisher's Exact Test* row.

## The lab

Type or step the counts. *× 2* and *÷ 2* change N without changing the pattern; *Make independent* sets every count to its expected value. Reach the four goals to open stage 2.

> **APA note:** χ²(df, *N* = …) = …, *p* = …, *V* = ….

## Mission

The lab's starting table is in `counts` (rows: method; columns: passed, did not pass).

1. Store Pearson's χ² test (no correction) in `pearson`, and its expected counts in `expected`.
2. Store the Pearson residuals in `resid`.
3. Store Cramér's V, worked out by hand from `pearson`, in `v`.
4. Store R's default test (with Yates' correction) in `yates` and Fisher's exact test in `fisher`.

Which of the three p-values is smallest? Why does the correction move it?

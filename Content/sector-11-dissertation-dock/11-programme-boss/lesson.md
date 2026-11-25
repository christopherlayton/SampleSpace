# Which Programme Lasted?

**Boss level.** Sixty teachers took one of three professional-development programmes: a **Workshop**, one-to-one **Coaching**, or an **Online** course (20 each). Their teaching self-efficacy (1–9) was measured before (`efficacy_t1`), at the end (`efficacy_t2`) and at a follow-up months later (`efficacy_t3`).

The Variance Rift looked at the end-of-programme scores. A dissertation committee would ask the harder question: **did the gains last?**

**Research question:** does the change in self-efficacy from before the programme to the follow-up (`gain = efficacy_t3 − efficacy_t1`) differ between programmes? If it does, which programmes differ?

## The seven steps

1. **Import** the CSV, put `programme` in the order Workshop, Coaching, Online, and compute `gain`.
2. **Describe** `gain` per programme: *n*, *M*, *SD*.
3. **Assumptions.** Levene's test, SPSS-style. Then fit the ANOVA (`aov()`) and test its **residuals** for normality: ANOVA assumes normal errors, and the residuals are the errors' estimates.
4. **ANOVA** table and η² (for a one-way design, η² and partial η² are the same).
5. **Post hoc** comparisons with Tukey's HSD, which keeps the familywise error rate at .05 across all three pairs.
6. **Plot** the gains by programme.
7. **Write it up**: the decision, then *F* with both df, *p* and η². Name the programme the post hoc tests single out, if any.

> **APA for ANOVA:** *F*(df between, df within), for example *F*(2, 45) = 4.31, *p* = .019, η² = .16. η² can't exceed 1, so no leading zero; *F* can, so it keeps two decimals and its leading digit.

readr, dplyr, car, effectsize and ggplot2 are yours to load; `fmt_num()`, `fmt_p()` and `fmt_bounded()` are loaded.

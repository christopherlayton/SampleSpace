# Two Separate Crews

The wellbeing study randomly assigned 40 students to a mindfulness programme or a control group. Did their anxiety differ after the programme?

- **H₀:** μ(control) = μ(mindfulness)
- **H₁:** μ(control) ≠ μ(mindfulness)

## The formula interface

```r
t.test(anxiety_post ~ group, data = survey)
```

Read `~` as "by": anxiety_post *by* group. The outcome goes on the left, the grouping variable (exactly two groups) on the right. Rows with a missing outcome are left out, so here 37 students are compared.

## Welch or Student?

| | Assumes equal variances? | df | R |
|---|---|---|---|
| **Welch's t** | no | adjusted, usually not a whole number | default |
| **Student's t** | yes | *n*₁ + *n*₂ − 2 | `var.equal = TRUE` |

Welch's test loses almost nothing when the variances *are* equal and protects you when they aren't, especially with unequal group sizes. Report whichever you used, and say so.

## Which way round?

R subtracts the **second** group from the **first**, in factor-level order (alphabetical for text): here Control − Mindfulness. A positive *t* means the control group scored higher. To flip it, set the order with `factor(group, levels = c("Mindfulness", "Control"))`. The test is the same; only the signs change.

> **Coming from SPSS?** *Analyze → Compare Means → Independent-Samples T Test*, with *Define Groups*. R needs no group codes: it uses the two values it finds.

## Mission

1. Import `wellbeing_survey.csv` into `survey`.
2. Store Welch's test of `anxiety_post` by `group` in `welch`, and Student's test in `student`.
3. Store Welch's df in `welch_df` and its p-value in `p_welch` (plain numbers).
4. Store the difference in means, Control − Mindfulness, in `diff_means`.

The result may surprise you. Keep it in mind for the paired test later in this sector.

# t-Test Translator

Back to the teaching study from the Data Frame Docks: 30 students, taught by lecture or by active learning. Here's what SPSS gives for their exam scores. Match it in R.

{{spss}}

## Reading the Independent Samples Test

Read it from left to right:

1. **Levene's Test**: *F* = .625, Sig. = .436. No evidence the variances differ.
2. So SPSS users read the **Equal variances assumed** row: Student's *t*(28) = −2.75. (Many statisticians would read the second row, Welch's, regardless. Here they agree.)
3. **Two-Sided p** = .010 for the usual two-sided test. Recent SPSS versions also print a **One-Sided p**, which is half of it; use it only for a direction stated in advance.
4. **Mean Difference** is Lecture − Active learning (group 1 − group 2), and the CI is for that difference.

Every number comes from three R calls:

| SPSS | R |
|---|---|
| Levene's *F* and Sig. | `leveneTest(score ~ method, data = teach, center = mean)` |
| Equal variances assumed | `t.test(score ~ method, data = teach, var.equal = TRUE)` |
| Equal variances not assumed | `t.test(score ~ method, data = teach)` |

The method column holds SPSS codes 1 and 2 with value labels; `haven::as_factor()` turns them into a factor in the same order, so R also subtracts Active learning from Lecture.

> **SPSS 27 and later** can add an *Independent Samples Effect Sizes* table with Cohen's *d*. That's the next level but one.

## Mission

1. Load haven and car; import `teaching_study.sav` into `teach` and make `method` a factor with `as_factor()`.
2. Store SPSS's Levene test in `levene`, the equal-variances row in `student` and the unequal-variances row in `welch`.
3. Store the Levene *F* in `levene_f`, Welch's df in `welch_df`, and Student's one-sided p in `p_one_sided`.

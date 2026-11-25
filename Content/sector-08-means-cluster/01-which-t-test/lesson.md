# Which t-Test?

Welcome to the Means Cluster. Every *t*-test compares means and asks the same question: is the difference big compared with its standard error?

**t = (difference in means) / SE of that difference**

What changes between the three *t*-tests is which means you compare, and so how the SE is worked out.

| Design | Test | R |
|---|---|---|
| one group vs a known value | **one-sample** | `t.test(x, mu = 28)` |
| two groups of different people | **independent-samples** | `t.test(score ~ group, data = df)` |
| the same people twice (or matched pairs) | **paired-samples** | `t.test(before, after, paired = TRUE)` |

## Assumptions

| Assumption | How to check | If it fails |
|---|---|---|
| **Independence**: one person's score doesn't affect another's | the design (not a test) | a different model (e.g. multilevel) |
| **Normality** of scores within each group (paired: of the differences) | histogram, Q–Q plot, Shapiro–Wilk | usually fine with 30+ per group; otherwise a rank-based test |
| **Equal variances** (Student's independent t only) | Levene's test, comparing SDs | use Welch's t (R's default) |

> **Coming from SPSS?** *Analyze → Compare Means* has all three: *One-Sample T Test*, *Independent-Samples T Test* and *Paired-Samples T Test*.

> **From the Crew Log:** this sector's question is a two-group one: do military and civilian astronauts fly missions of different lengths? You'll answer it at the end, one row per person.

## Mission

A **briefing**: six questions on the right.

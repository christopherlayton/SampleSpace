# F Forecast

Predict what R prints before it runs.

## F in R

| Function | Gives |
|---|---|
| `pf(f, df1, df2, lower.tail = FALSE)` | p: the area above f |
| `qf(0.95, df1, df2)` | the critical F for α = .05 |
| `summary(aov(...))[[1]]` | the ANOVA table as a data frame |

F is always positive and a larger F is more evidence against H₀, so an F test only looks at the upper tail.

## Two traps

- **Numeric group codes.** If the groups are stored as 1, 2, 3, `aov()` treats them as a number and fits a straight line (1 df). `factor()` first.
- **Two groups.** A one-way ANOVA on two groups gives F = t², with the same p as Student's t-test.

## Adjusting p-values

When you run several tests, `p.adjust()` scales the p-values so you can keep comparing them with .05:

- **Bonferroni:** each p × the number of tests (capped at 1). Simple and conservative.
- **Holm:** sorts the p-values and multiplies by m, m − 1, …, 1. Same protection, more power.

Pick an answer for each question. Once you answer, the code runs in real R.

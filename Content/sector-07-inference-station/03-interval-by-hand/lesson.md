# Interval by Hand

CI Rain showed what a confidence interval *does*. Now build one yourself, so that `t.test()`'s output holds no mysteries.

## The recipe

**95% CI = M ± t* × SE**

| Piece | What it is | R |
|---|---|---|
| *M* | the sample mean | `mean(x)` |
| SE | SD / √*n* | `sd(x) / sqrt(length(x))` |
| *t** | the value cutting off 2.5% in each tail of a *t* distribution with *n* − 1 df | `qt(0.975, df = n - 1)` |

Why *t* and not 1.96? Because the SE uses the *sample* SD, which is itself uncertain. The *t* distribution has heavier tails to allow for that. With large samples *t** shrinks towards 1.96; with 40 people it's about 2.02.

The interval's half-width, *t** × SE, is the **margin of error**.

## Check against R

`t.test(x)$conf.int` returns the same interval. (It also carries an attribute saying the confidence level, which is why it prints with an extra line.)

> **Coming from SPSS?** *Analyze → Descriptive Statistics → Explore* prints "95% Confidence Interval for Mean, Lower Bound / Upper Bound". It's the same calculation.

> **APA note:** *M* = 29.63, 95% CI [28.02, 31.23]. Square brackets, same decimals as the mean.

## Mission

1. Import `wellbeing_survey.csv` into `survey` and store the pre-test anxiety scores in `x`.
2. Store the mean in `m`, the standard error in `se` and the critical *t* value in `t_crit`.
3. Store the interval `c(lower, upper)` in `ci_by_hand`.
4. Store `t.test(x)$conf.int` in `ci_r`. Do they agree?

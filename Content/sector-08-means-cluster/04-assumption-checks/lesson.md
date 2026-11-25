# Assumption Checks

Before trusting a *t*-test, check what it assumes. Your committee will ask, and SPSS users are used to seeing Levene's test in every *t*-test table.

## Normality

The independent *t*-test assumes the outcome is roughly normal **within each group**. Two ways to check:

| Check | R | Read it |
|---|---|---|
| **Q–Q plot** | `qqnorm(x); qqline(x)` | points close to the line → close to normal; curves at the ends → skew or heavy tails |
| **Shapiro–Wilk** | `shapiro.test(x)` | p < .05 → evidence of non-normality |

With small groups Shapiro–Wilk has little power to spot problems; with large groups it flags trivial ones. Look at the plot too, and remember that with 30 or more per group the *t*-test copes well with moderate non-normality.

## Equal variances: Levene's test

`leveneTest()` lives in the **car** package. It tests H₀: the groups' variances are equal.

```r
library(car)
leveneTest(anxiety_post ~ factor(group), data = survey)                 # centred on the median
leveneTest(anxiety_post ~ factor(group), data = survey, center = mean)  # SPSS's version
```

car's default centres on the median (the *Brown–Forsythe* variant, which is more robust); SPSS centres on the mean. Wrap the group in `factor()` so car knows it's a grouping variable.

**If Levene's p < .05:** the variances differ, so use Welch's *t* (R's default anyway). Many statisticians skip the Levene step and always use Welch. Either way, report what you did.

> **APA note:** "Levene's test indicated unequal variances, *F*(1, 35) = 4.51, *p* = .041, so Welch's *t*-test was used."

## Mission

1. Load readr and car; import `wellbeing_survey.csv` into `survey`.
2. Store the post-test anxiety of each group in `control` and `mindful`, and the Shapiro–Wilk p-values in `sw_control` and `sw_mindful`.
3. Store Levene's test centred on the median in `levene_median`, and SPSS's version in `levene_mean`.
4. Store the p-value of SPSS's version in `levene_p`.
5. Draw a normal Q–Q plot of `control` with its reference line.

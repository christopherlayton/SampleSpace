# Line of Best Fit

In the Least-Squares Fit lab you found the line by hand. `lm()` (*linear model*) finds it exactly and tells you how sure to be about it.

```r
model <- lm(morale_score ~ sleep_hours, data = sleep)
summary(model)
```

## Reading `summary()`

| Part | Means | SPSS table |
|---|---|---|
| `(Intercept)` estimate, *b*₀ | predicted morale at 0 hours of sleep (often not meaningful) | Coefficients, (Constant) B |
| `sleep_hours` estimate, *b*₁ | change in predicted morale per extra hour of sleep | Coefficients, B |
| Std. Error, t value, Pr(>\|t\|) | the test of H₀: slope = 0 | Std. Error, t, Sig. |
| Multiple R-squared | share of morale's variance explained | Model Summary, R Square |
| F-statistic | the test of the whole model | ANOVA table |

With one predictor, the slope's *t*-test, the model's F test (F = t²) and the test of Pearson's r all give the same *p*.

## Pieces you'll want

```r
coef(model)                 # b0 and b1
confint(model)              # 95% CIs for both
summary(model)$r.squared
predict(model, newdata = data.frame(sleep_hours = 8))
```

## Standardised slopes

SPSS prints a **Beta** column: the slope when both variables are in z-scores. Get it by scaling both:

```r
lm(scale(morale_score) ~ scale(sleep_hours), data = sleep)
```

With one predictor, β is exactly Pearson's r.

> **APA note:** report *b* with its CI and the model's *R*², e.g. "Each additional hour of sleep predicted .xx points higher morale, *b* = .xx, 95% CI [.xx, .xx], *t*(44) = …, *p* = …, *R*² = .xx."

## Mission

`sleep` is loaded from `sleep_morale.csv`.

1. Fit the regression of morale on sleep in `model` and print its summary.
2. Store the slope in `b` (a single number) and the slope's 95% CI in `b_ci` (the `sleep_hours` row of `confint()`).
3. Store `r_squared`.
4. Store the predicted morale for 8 hours of sleep in `pred_8`.
5. Store the standardised slope β in `beta`, and check it against `cor()`.

# Regression Forecast

Predict what R prints before it runs.

## Facts worth knowing

- The least-squares line passes through **(x̄, ȳ)**.
- Slope: *b* = Σ(x − x̄)(y − ȳ) ÷ Σ(x − x̄)², which is also *r* × (SD of y ÷ SD of x).
- With one predictor, ***R*² = *r*²**.
- `lm(y ~ x)` and `lm(x ~ y)` are **different lines**: each minimises errors in its own outcome.
- `lm(y ~ 1)` predicts the mean for everyone.
- A **factor** predictor becomes 0/1 dummy variables: the intercept is the reference group's mean, each coefficient a difference from it. That's why a *t*-test is a regression with one dummy, and a one-way ANOVA a regression with k − 1.

## Reading printed coefficients

`coef()` returns a **named** vector, so R prints the names above the values:

```
(Intercept)           x 
        2.2         0.6 
```

Pick an answer for each question. Once you answer, the code runs in real R.

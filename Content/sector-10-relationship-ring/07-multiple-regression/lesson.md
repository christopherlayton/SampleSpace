# Many Predictors

Does a teacher's workload predict their self-efficacy at follow-up (`efficacy_t3`), **over and above** where they started (`efficacy_t1`)? One predictor at a time can't answer that. Multiple regression can:

```r
model <- lm(efficacy_t3 ~ efficacy_t1 + workload_hours + years_teaching, data = pd)
```

## Holding the others constant

Each slope is now a **partial** effect: the change in the outcome per unit of that predictor *with the other predictors held constant*. That's why a predictor's slope can shrink, vanish or flip sign when others join the model.

## Standardised betas

SPSS's **Beta** column puts every predictor on the same scale (SD units), so they can be compared: `effectsize::standardize_parameters(model)`.

## Hierarchical regression (SPSS's blocks)

In SPSS you enter predictors in **blocks** and read *R Square Change* and *Sig. F Change*. In R, fit each block as its own model and compare them:

```r
base <- lm(efficacy_t3 ~ efficacy_t1, data = pd)          # block 1
anova(base, model)                                          # does block 2 add anything?
summary(model)$r.squared - summary(base)$r.squared         # R² change
```

The models must use the **same rows** (watch for missing values in the later block's predictors).

## Checking the model

| Check | R | Look for |
|---|---|---|
| Linearity, equal variance | `plot(model, which = 1)`, residuals vs fitted | a shapeless band around 0 |
| Normal residuals | `plot(model, which = 2)`, Q–Q plot | points near the line |
| Multicollinearity | `car::vif(model)` | VIF well under 5 (some say 10) |
| Influential cases | `plot(model, which = 5)`, Cook's distance | points far beyond the dashed lines |

**Adjusted R²** penalises extra predictors, so it only rises if a predictor earns its place.

> **APA note:** give a table of *b*, *SE*, β, *t* and *p* for each predictor with the model's *R*² (and adjusted *R*²), *F*(df₁, df₂) and *p*; for blocks, Δ*R*² and its *F* test.

## Mission

`pd` is loaded with car and effectsize.

1. Fit block 1 (`efficacy_t1` only) in `base` and the full model (adding `workload_hours` and `years_teaching`) in `model`; print the full summary.
2. Store the full model's `r2` and `adj_r2`, and the R² change from `base` in `r2_change`.
3. Store the F test of that change, `anova(base, model)`, in `change_test`.
4. Store the standardised coefficients in `betas` and the VIFs in `vifs`.
5. Draw the residuals-vs-fitted and the Q–Q plot of `model`.

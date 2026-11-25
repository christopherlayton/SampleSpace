# Regression Translator

Back in the Relationship Ring you fitted this line: crew morale predicted by hours of sleep (46 crew members with complete data). Here is the same model from SPSS's Linear Regression dialog. Translate it, then write the sentence for the results chapter.

{{spss}}

## Table by table

| SPSS | R |
|---|---|
| Model Summary: R, R Square, Adjusted R Square | `summary(fit)$r.squared`, `$adj.r.squared`; R is √R² with one predictor |
| Std. Error of the Estimate | `summary(fit)$sigma` |
| ANOVA: F, df, Sig. | `summary(fit)$fstatistic` (value, numdf, dendf); p from `pf(..., lower.tail = FALSE)`, or `anova(fit)` |
| Coefficients: B, Std. Error, t, Sig. | `coef(summary(fit))` |
| Standardized Beta | *b* × *SD*(x) / *SD*(y), or `effectsize::standardize_parameters(fit)` |

## Sig. = .001 isn't p = .001

SPSS rounds *Sig.* to three decimals. Its ".001" here is a p of about .00056, which rounds **up** to .001. APA reports values below .001 as *p* < .001, so copying SPSS's ".001" into the text would be wrong. Computing p in R and formatting it with `fmt_p()` avoids the trap.

## The APA sentence

A simple regression is usually reported with the model's *F* test, *R*², and the slope:

> Hours of sleep predicted crew morale, *F*(1, 44) = …, *p* …, *R*² = …, *b* = … .

`fmt_num()`, `fmt_p()` and `fmt_bounded()` from APA Numbers are loaded.

## Mission

`sm` is loaded.

1. Fit the model in `fit` and store `summary(fit)` in `fit_summary`.
2. Store SPSS's standardized Beta in `beta` and the model's p-value in `p` (not rounded).
3. Store the APA fragment in `write_up`: *F* with both df, *p*, *R*² (no leading zero) and the slope *b*.

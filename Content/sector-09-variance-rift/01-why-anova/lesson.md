# Why ANOVA?

Welcome to the Variance Rift. Here the question has more than two groups: do teachers in three professional-development programmes (Workshop, Coaching, Online) end up with different self-efficacy?

## Why not three t-tests?

Three pairwise *t*-tests at α = .05 give three chances of a false alarm. With no real differences anywhere, the chance of at least one "significant" result is about 1 − .95³ ≈ .14, not .05. With six groups (15 pairs) it passes .50. **Analysis of variance** asks one question about all the means at once.

- **H₀:** μ₁ = μ₂ = μ₃ (all population means are equal)
- **H₁:** at least one mean differs

## Splitting the variation

Every score's distance from the **grand mean** splits into two parts:

| Part | Distance | Sum of squares |
|---|---|---|
| Between groups | group mean − grand mean | SS between |
| Within groups | score − its group mean | SS within |
| Total | score − grand mean | SS total = SS between + SS within |

Dividing each SS by its degrees of freedom gives a **mean square** (a variance), and

**F = MS between ÷ MS within**

If H₀ is true, both mean squares estimate the same noise and F is about 1. Real differences between groups make MS between, and F, larger. The *p*-value comes from the F distribution with *k* − 1 and *N* − *k* degrees of freedom.

## After the F

- A significant F says the means aren't all equal, not **which** differ: that's **post hoc** tests (Tukey HSD), which keep the familywise error at α.
- **η²** = SS between ÷ SS total is the effect size: the share of the variation that lies between groups.
- **Assumptions:** independent observations, roughly normal residuals, similar variances (Levene's test; Welch's ANOVA when they differ).

> **Coming from SPSS?** *Analyze → Compare Means → One-Way ANOVA*, or *Analyze → General Linear Model → Univariate* for designs with more factors. In R: `aov()` with `summary()`.

> **APA note:** *F*(2, 57) = 4.33, *p* = .018, η² = .13. Italicise *F* and *p*; give both df.

## Three kinds of ANOVA in this sector

| Design | Example | R |
|---|---|---|
| One-way, between groups | three programmes, different teachers | `aov(score ~ programme)` |
| Factorial (two-way) | programme × experience | `aov(score ~ programme * experience)` |
| Repeated measures | the same teachers at three time points | `afex::aov_ez(..., within = "time")` |

Answer the questions on the right to continue.

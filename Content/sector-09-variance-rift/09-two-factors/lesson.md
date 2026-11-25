# Two-Factor Field

Two questions at once: does self-efficacy at the end depend on the **programme**, on the teacher's **experience** (early career or experienced), and does the programme's effect **depend on** experience? The study is a 3 × 2 design with 10 teachers in each of the six cells.

## Main effects and the interaction

| Term | Question |
|---|---|
| `programme` | averaged over experience, do the programmes differ? |
| `experience` | averaged over programme, do early-career and experienced teachers differ? |
| `programme:experience` | is the programme effect different for early-career and experienced teachers? |

`programme * experience` in a formula is shorthand for all three: `programme + experience + programme:experience`.

**Plot the cell means.** Parallel lines mean no interaction; lines that converge, diverge or cross suggest one. When an interaction is real, interpret the main effects with care: "Coaching helps" may only be true for some teachers.

## Type I and Type III

SPSS's *GLM Univariate* tests each effect **after all the others** (Type III sums of squares). R's `aov()` tests them **in the order written** (Type I). In a **balanced** design like this one, with equal cell sizes, the two agree. With unequal cells they don't, and to match SPSS you need Type III, which **afex** does for you:

```r
library(afex)
factorial <- aov_car(efficacy_t2 ~ programme * experience + Error(id), data = pd)
anova(factorial, es = "pes")
```

`Error(id)` names the column that identifies each person (each appears once here). afex sets sum-to-zero contrasts, which Type III tests need, and says so in a message.

## Effect sizes

With several factors, report **partial η²**: SS effect ÷ (SS effect + SS error), the share of the variance not explained by the other effects that this effect explains. SPSS's *Estimates of effect size* option gives the same. afex's default `ges` is *generalised* η², which suits comparisons across designs.

> **APA note:** one line per effect, e.g. *F*(2, 54) = …, *p* = …, η²p = …, and describe the interaction with the cell means or a figure.

## Mission

`pd` is loaded with afex, dplyr, effectsize and ggplot2.

1. Store the six cell means (`n` and `mean` of `efficacy_t2` for each programme × experience) in `cells`.
2. Fit the factorial ANOVA with `aov()` in `fit2` and print its summary.
3. Fit it with afex's `aov_car()` in `factorial`, and print `anova(factorial, es = "pes")`.
4. Store partial η² for each effect from `fit2` in `pes`.
5. Store an interaction plot of `cells` in `p`: programme on x, mean on y, a coloured line per experience group.

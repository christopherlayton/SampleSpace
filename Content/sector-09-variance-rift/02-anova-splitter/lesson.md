# ANOVA Splitter

ANOVA's name says what it does: it **analyses variance** by splitting it. Every score's distance from the grand mean (the dashed line) is two distances added together:

- from the grand mean to its **group mean** (between groups), and
- from the group mean to the **score** (within groups).

Square and add them up and **SS total = SS between + SS within**, the bar under the chart.

## From SS to F

| Source | SS | df | MS = SS ÷ df |
|---|---|---|---|
| Between groups | Σ nⱼ (group mean − grand mean)² | k − 1 | MS between |
| Within groups | Σ (score − group mean)² | N − k | MS within |

**F = MS between ÷ MS within**, and *p* is the area of the F distribution above it (the small curve; the red tail is *p*). In R that area is `pf(f, df1, df2, lower.tail = FALSE)`.

## The lab

Drag a group up or down to move its mean, or use the sliders: *Distance between means* spreads them evenly, *SD within groups* sets the noise, and *People per group* adds data. *Show deviations* draws the within, between or total distances. Reach the four goals to open stage 2.

> **Coming from SPSS?** The ANOVA table in SPSS's One-Way ANOVA output has these same rows: Between Groups, Within Groups, Total, with Sum of Squares, df, Mean Square, F and Sig.

## Mission

Now split real data by hand. `pd_study.csv` holds 60 teachers in three professional-development programmes; `efficacy_t2` is their self-efficacy (1–9) at the end. The grand mean is done for you.

1. Store each programme's mean in `means` and its size in `n` with `tapply()`.
2. Store `ss_between` and `ss_within`.
3. Store `f` (df 2 and 57) and its `p` from `pf()`.
4. Store η² in `eta_sq`.
5. Check your table against `summary(aov(efficacy_t2 ~ programme, data = pd))`.

# Kinds of Connection

Welcome to the Relationship Ring. The Means Cluster and the Variance Rift compared groups on a numeric outcome. Here the question is whether two variables are **connected**, and the variables' types pick the method.

| Variables | Question | Method | Effect size |
|---|---|---|---|
| two numeric | how strongly do they go together? | correlation, `cor.test()` | *r* |
| numeric outcome, numeric (or several) predictors | how much does y change with x? | regression, `lm()` | *b*, *R*² |
| two categorical | are they independent? | χ² test, `chisq.test()` | Cramér's *V* |

## Correlation and regression

**Pearson's r** (−1 to +1) measures how closely two numeric variables follow a straight line; it's symmetric. **Spearman's rho** does the same on ranks, for monotonic patterns or when outliers worry you.

**Regression** has a direction: an **outcome** predicted from a **predictor**. Its **slope** *b* says how much the outcome changes, in its own units, per unit of the predictor, and its **R²** is the share of the outcome's variance the model explains. With one predictor, R² = r².

## Chi-square

For two categorical variables, count each combination in a **contingency table**. If the variables are independent, each cell's **expected** count is (row total × column total) ÷ N. χ² adds up how far the observed counts are from those expectations.

## What none of them say

- A connection is not a **cause**: a third variable can drive both, or the arrow can point the other way.
- *r* and *b* describe **straight-line** relationships: always plot the data.
- A tiny *p* with a huge N can go with a trivially small *r* or *V*. Report the effect size.

> **APA note:** *r*(44) = .49, *p* < .001; *b* = 0.70, 95% CI [0.32, 1.08]; χ²(1, *N* = 30) = 6.53, *p* = .011, *V* = .47. χ² reports its df **and** N.

Answer the questions on the right to continue.

# Round Trip

A full analysis, start to finish, in Python: the Dissertation Dry Run's first research question, through the wormhole.

> **RQ:** Do women and men differ in their age at their first spaceflight?

One row per astronaut (their first mission). The steps are the ones you know from the Bosses in R: **import → describe → plot → check → test → write up**. Each step's checks open the next.

## The pieces

You have met every tool in this sector. Two new things:

**Selecting a group's values** for scipy:

```python
women = first.loc[first["sex"] == "female", "age"]
```

**f-strings** build a sentence from numbers, the job `sprintf()` and inline `r` code did in R. Put `f` before the quote, and each `{...}` is filled in; `:.2f` rounds to two decimals:

```python
f"M = {women.mean():.2f}"                  # "M = 38.12"
f"t({welch.df:.2f}) = {welch.statistic:.2f}"
```

APA wants *p* without a leading zero, and "*p* < .001" below .001:

```python
p_text = "p < .001" if welch.pvalue < .001 else f"p = {welch.pvalue:.3f}".replace("0.", ".", 1)
```

## Mission

Write the whole analysis in one script.

1. **Import** pandas as `pd`, numpy as `np`, `stats` from scipy, seaborn as `sns` and matplotlib's pyplot as `plt`. Read `astronauts.csv` into `log`, and make `first` (first missions only) with an `age` column.
2. **Describe**: store the `count`, `mean` and `std` of `age` for each `sex` in `by_sex`.
3. **Plot**: a boxplot of `age` by `sex`, y label "Age at first flight", finished with `plt.show()`.
4. **Check**: store women's ages in `women` and men's in `men`, and Levene's test (centred on the mean) in `levene`.
5. **Test**: store Welch's *t*-test with **women first** in `welch`, and Cohen's *d* (women − men, pooled SD) in `d`.
6. **Write it up**: store `"reject"` or `"fail to reject"` (α = .05) in `decision`, and an APA results sentence in `sentence`, built with an f-string, that reports both groups' *M*, then *t*(df) with two decimals, *p* and *d*. Don't type any of the numbers.

Then print your sentence and read it. What would you conclude, and how big is the difference in years?

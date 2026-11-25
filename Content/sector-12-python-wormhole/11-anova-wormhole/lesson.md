# ANOVA Wormhole

The Variance Rift's question: **does age at first flight differ across the decades?** In Python, models with formulas come from **statsmodels**, whose formulas read like R's:

```python
import statsmodels.api as sm
import statsmodels.formula.api as smf

model = smf.ols("age ~ C(decade)", data=first).fit()
table = sm.stats.anova_lm(model, typ=2)
```

`C(decade)` says "treat decade as categorical", the job `factor()` does in R. Without it, statsmodels would fit a straight line through the decade *numbers* (1 df instead of 5): the same trap as numeric group codes in `aov()`.

`smf.ols()` fits the model (like `lm()`), and `anova_lm()` turns it into an ANOVA table: `sum_sq`, `df`, `F` and `PR(>F)` (the *p*-value). `typ=2` asks for Type II sums of squares; with one factor every type gives the same table.

## After the omnibus test

| R | Python |
|---|---|
| `eta_squared(fit)` | `table["sum_sq"].iloc[0] / table["sum_sq"].sum()` |
| `TukeyHSD(fit)` | `pairwise_tukeyhsd(first["age"], first["decade"])` |
| `leveneTest(age ~ decade, center = mean)` | `stats.levene(*groups, center="mean")` |
| `oneway.test(age ~ decade)` | `anova_oneway(first["age"], first["decade"], use_var="unequal")` |

`stats.levene()` takes each group as its own argument. `*` unpacks a list into arguments, so `stats.levene(*[g["age"] for _, g in first.groupby("decade")], center="mean")` passes the six decades' ages. (`for _, g in first.groupby(...)` walks through the groups; `_` is the decade, which isn't needed.)

{{twin}}

## Mission

`log` is loaded, with `pd`, `np`, `stats`, `sm`, `smf`, `pairwise_tukeyhsd` and `anova_oneway` imported.

1. Make `first`: first missions only, with `age` and `decade` (e.g. 1980).
2. Fit `model` (age by decade, as categories) and store its ANOVA table in `table`.
3. Store η² in `eta2`.
4. Store Tukey's HSD comparisons in `tukey`; print its `summary()`.
5. Store Levene's test (centred on the mean) in `levene` and Welch's ANOVA in `welch`.
6. Store the test that fits in `test_used` (`"welch"` if Levene's *p* < .05, else `"classic"`) and your decision at α = .05 from that test in `decision`.

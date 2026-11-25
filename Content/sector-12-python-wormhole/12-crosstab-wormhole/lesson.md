# Crosstab Wormhole

The Relationship Ring's question: **was the share of women among first-time flyers different from 2000 on than before?**

## Order the categories

pandas sorts text alphabetically, so `"2000 on"` would come before `"before 2000"`. A **categorical** column keeps the order you give it, the job `factor(levels = ...)` does in R:

```python
era = pd.Categorical(np.where(first["year_of_mission"] >= 2000, "2000 on", "before 2000"),
                     categories=["before 2000", "2000 on"])
first = first.assign(era=era)
```

`np.where(condition, yes, no)` is R's `ifelse()`.

## The table and the test

| R | Python |
|---|---|
| `table(first$era, first$sex)` | `pd.crosstab(first["era"], first["sex"])` |
| `prop.table(tab, margin = 1)` | `pd.crosstab(..., normalize="index")` |
| `chisq.test(tab, correct = FALSE)` | `stats.chi2_contingency(tab, correction=False)` |
| `test$expected` | `chi.expected_freq` |
| `cramers_v(tab, adjust = FALSE)` | √(χ² / (*N* × (min(rows, columns) − 1))) |

Like R, scipy applies **Yates' continuity correction** to a 2 × 2 table unless you switch it off; SPSS's "Pearson Chi-Square" row is the uncorrected one. The result has `chi.statistic`, `chi.pvalue`, `chi.dof` and `chi.expected_freq`.

{{twin}}

## Mission

`log` is loaded, with `pd`, `np` and `stats` imported.

1. Make `first` (first missions) with an ordered `era` column: `"before 2000"`, then `"2000 on"`.
2. Store the counts of era by sex in `crew_table` and the row percentages in `row_pct`.
3. Store the uncorrected chi-square test in `chi`, and whether every expected count is at least 5 in `expected_ok`.
4. Store Cramér's *V* in `v`.

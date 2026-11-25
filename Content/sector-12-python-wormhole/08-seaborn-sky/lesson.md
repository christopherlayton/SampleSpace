# Seaborn Sky

Python's plotting is in two layers. **matplotlib** draws (axes, labels, figures); **seaborn** sits on top and makes statistical plots from a data frame in one call, a little like ggplot2's geoms:

| ggplot2 | seaborn |
|---|---|
| `ggplot(log, aes(x = hours_mission)) + geom_histogram(bins = 40)` | `sns.histplot(data=log, x="hours_mission", bins=40)` |
| `ggplot(first, aes(x = decade, y = age)) + geom_boxplot()` | `sns.boxplot(data=first, x="decade", y="age")` |
| `geom_point()` | `sns.scatterplot(...)` |
| `labs(x = "…", y = "…")` | `plt.xlabel("…")`, `plt.ylabel("…")` |
| printing the plot | `plt.show()` |

```python
import seaborn as sns
import matplotlib.pyplot as plt

sns.histplot(data=log, x="hours_mission", bins=40)
plt.xlabel("Hours per mission")
plt.show()
```

Each `plt.show()` finishes one figure (it appears in the Plots tab); the next plot starts a new one. Without `plt.show()` in between, seaborn draws the second plot on top of the first.

> `//` is whole-number division, so `1987 // 10 * 10` is 1980: a quick way to make a decade.

{{twin}}

## Mission

`log` is loaded, with pandas as `pd`.

1. Import seaborn as `sns` and matplotlib's pyplot as `plt`.
2. Draw a histogram of `hours_mission` with 40 bins, x label "Hours per mission", and show it.
3. Make `first` (first missions only) with `age` and `decade` columns.
4. Draw a boxplot of `age` by `decade`, y label "Age at first flight", and show it.

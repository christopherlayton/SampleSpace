# Describe in Python

Back in the Descriptive Drift you found that the mean mission (about 1,051 h) is four times the median (261 h): a few long station stays drag the mean up. Here is the same description in pandas.

```python
hours = log["hours_mission"]
hours.mean(), hours.median()
hours.std()          # sample SD: divides by n − 1, like sd() and SPSS
hours.describe()     # count, mean, std, min, quartiles, max
```

## The *n* − 1 trap

numpy and pandas disagree about the standard deviation:

| | divides by | same as |
|---|---|---|
| `hours.std()` (pandas) | *n* − 1 | R's `sd()`, SPSS |
| `np.std(hours)` (numpy) | *n* | a population SD |
| `np.std(hours, ddof=1)` | *n* − 1 | R's `sd()` |

`ddof` ("delta degrees of freedom") is what is subtracted from *n*. With 1,277 missions the difference is tiny; with 10 participants it isn't. In a write-up you want the *n* − 1 version.

## Shape

`hours.skew()` and `hours.kurt()` give the bias-adjusted skewness and *excess* kurtosis, the same formulas as SPSS and `psych::describe(type = 2)`. pandas' quartiles (`quantile()`) use R's default method, `type = 7`; SPSS's percentiles match R's `type = 6`, so expect small differences from SPSS output.

{{twin}}

## Mission

`log` is loaded, with pandas as `pd` and numpy as `np`.

1. Store the `hours_mission` column in `hours`, and its mean and median in `mean_hours` and `median_hours`.
2. Store the sample SD in `sd_hours` and numpy's default SD in `sd_numpy`.
3. Store the skewness in `skew_hours` and the excess kurtosis in `kurt_hours`.
4. Store the interquartile range in `iqr_hours`, and show `hours.describe()`.

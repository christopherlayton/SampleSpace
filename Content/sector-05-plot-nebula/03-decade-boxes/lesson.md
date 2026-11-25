# Decade Boxes

A boxplot squeezes a distribution into five numbers: the box runs from the 25th to the 75th percentile (the IQR), the line inside is the **median**, the whiskers reach the furthest values within 1.5 × IQR of the box, and anything beyond is drawn as a point.

Boxplots shine at **comparing groups**, side by side:

```r
ggplot(missions, aes(x = factor(decade), y = hours_mission)) +
  geom_boxplot()
```

`factor(decade)` tells ggplot to treat the decades as categories (one box each) rather than as a number line.

## Log scales

When values range from 1 to 10,000, a few huge values squash everything else into a line at the bottom. `scale_y_log10()` spaces 1, 10, 100, 1,000 and 10,000 equally, so both short and long missions are visible. The data aren't changed, only the axis.

The log of 0 is minus infinity, so six zero-hour missions (aborted launches) can't be placed. ggplot drops them and warns you, which is fine here, but always read that warning.

> **Coming from SPSS?** *Explore* draws boxplots by group, with SPSS's own outlier markers (○ and ✱). ggplot marks outliers with points by the 1.5 × IQR rule.

## Mission

1. Load readr, dplyr and ggplot2, import `astronauts.csv`, and store it with a new `decade` column (1960, 1970, …) in `missions`.
2. Store boxplots of `hours_mission` by decade in `p_box`, and draw it.
3. Store the same plot with a log-10 y-axis in `p_log`, and draw it.
4. Store each decade's median mission length in `decade_medians` (columns `decade` and `median_hours`).

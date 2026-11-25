# Error Bars

The classic results figure: a bar (or point) for each group's mean, with error bars. In ggplot you **summarise first, then plot the summary**.

## 1. Summarise

```r
post_summary <- survey |>
  group_by(group) |>
  summarise(n = sum(!is.na(anxiety_post)),
            mean_post = mean(anxiety_post, na.rm = TRUE),
            se = sd(anxiety_post, na.rm = TRUE) / sqrt(n))
```

The **standard error of the mean** is SD / √n: how much the mean would vary from sample to sample. Count only the non-missing values for *n*, or the SE comes out too small.

## 2. Plot

`geom_col()` draws bars at heights you supply (unlike `geom_bar()`, which counts). `geom_errorbar()` needs `ymin` and `ymax`:

```r
ggplot(post_summary, aes(x = group, y = mean_post)) +
  geom_col() +
  geom_errorbar(aes(ymin = mean_post - se, ymax = mean_post + se), width = 0.2)
```

## Say what the bars are

Error bars can show ±1 SD (spread of the data), ±1 SE (precision of the mean) or a 95% CI (about ±2 SE). They look the same and mean very different things, so **the caption must say which**. ±1 SE bars are the narrowest of the three.

> **A word against bar charts of means:** a bar hides how many people there are and how they're spread. With small samples, many journals now prefer points with CIs, or the raw data drawn on top (`geom_jitter()`). You'll see why in the Means Cluster.

> **Coming from SPSS?** *Chart Builder → Bar → Simple Bar*, with *Display error bars* ticked and *Standard error* chosen. Here you can see exactly what was computed.

## Mission

1. Load readr, dplyr and ggplot2 and import `wellbeing_survey.csv` into `survey`.
2. Store one row per group in `post_summary`, with `n`, `mean_post` and `se` for post-test anxiety.
3. Store a bar chart of the means with ±1 SE error bars (width 0.2) in `p_means`, and draw it.

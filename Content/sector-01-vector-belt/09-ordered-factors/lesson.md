# Likert Ladder

Some categories have a natural **order** but no meaningful distance between them: "Disagree" < "Neutral" < "Agree". That's an **ordinal** variable. R's version is an **ordered factor**.

Survey data usually arrive as numeric codes. `factor()` can attach the words and the order in one go:

```r
codes <- c(2, 3, 1)
factor(codes, levels = 1:3, labels = c("Low", "Medium", "High"), ordered = TRUE)
#> [1] Medium High   Low
#> Levels: Low < Medium < High
```

- `levels =` lists the codes that can appear, in order;
- `labels =` gives each code its words;
- `ordered = TRUE` makes the `<` order count.

## Why ordered?

With an ordered factor, comparisons make sense: `answers >= "Agree"` is TRUE for "Agree" and "Strongly agree". With a plain factor R would refuse, because unordered categories can't be compared.

> **A stats caution:** a single Likert item is ordinal, so the median and frequencies describe it safely. Many researchers do average Likert *scales* (the sum or mean of several items), treating them as roughly interval. That's a judgement call you'll need to justify in your methods section, not something R decides for you.

> **Coming from SPSS?** In Variable View this is setting *Measure* to *Ordinal* and adding Value Labels. In R the order is enforced: you can't accidentally compare categories the wrong way round.

## Mission

`agree` holds eight answers to "I feel confident using statistics", coded 1–5. `likert_labels` holds the words for 1 to 5.

1. Make `agree_f`, an **ordered** factor with levels 1:5 and the labels from `likert_labels`.
2. Store how many participants answered **Agree or higher** in `n_agree`.

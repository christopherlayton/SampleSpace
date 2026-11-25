# Which Average?

Welcome to Descriptive Drift. The ship's computer wants one number: *how long is a typical space mission?* There are three candidate answers.

| Measure | What it is | R |
|---|---|---|
| **Mean** | the sum divided by *n*; the balance point | `mean(x)` |
| **Median** | the middle value once sorted; half above, half below | `median(x)` |
| **Mode** | the most common value | no built-in function: use `table()` |

For a symmetric distribution the three agree. When a few values are far out in one direction, the **mean is pulled toward them** and the median isn't. One 10,000-hour station stay moves the mean of a thousand missions by about 10 hours; it moves the median by at most one place.

The mode is most useful for categories and small counts (the most common number of missions per astronaut), and almost useless for continuous measurements, where every value may be unique.

```r
counts <- table(c(1, 2, 2, 3, 2, 1))
names(counts)[which.max(counts)]   # "2"
```

> **Coming from SPSS?** These are the Mean, Median and Mode boxes in *Analyze → Descriptive Statistics → Frequencies → Statistics*.

## Mission

1. Load readr and import `astronauts.csv` into `astronauts`.
2. Store the mean mission length (hours) in `mean_hours` and the median in `median_hours`.
3. Using one row per astronaut (`mission_number == 1`), store the most common **total number of missions** per astronaut, as a number, in `mode_missions`.

Before you run it: which do you expect to be bigger, the mean or the median?

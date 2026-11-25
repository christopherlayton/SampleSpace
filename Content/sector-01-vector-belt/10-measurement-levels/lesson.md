# Belt Survey

Time to chart the whole Vector Belt. Before any analysis, decide each variable's **level of measurement** (Stevens, 1946). It decides which statistics make sense, and in R it decides which type the variable should be.

| Level | What it means | Examples | R type |
|---|---|---|---|
| Nominal | categories, no order | gender, condition, major | `factor()` |
| Ordinal | ordered categories, unequal or unknown gaps | Likert item, education level, rank | `factor(..., ordered = TRUE)` |
| Interval | equal gaps, no true zero | temperature in °C, most scale scores | numeric |
| Ratio | equal gaps and a true zero | age, reaction time, income | numeric |

R doesn't distinguish interval from ratio: both are numeric. The difference matters for interpretation (it makes sense to say 40 ms is twice 20 ms, but not that 20 °C is twice 10 °C).

**Which statistics fit?**

| Level | Centre | Typical tests |
|---|---|---|
| Nominal | mode, frequencies | chi-square |
| Ordinal | median | non-parametric tests (e.g. Mann–Whitney) |
| Interval/ratio | mean (*M*) and *SD* | *t*-tests, ANOVA, correlation, regression |

> **Coming from SPSS?** SPSS's *Measure* column (Nominal/Ordinal/Scale) is a label that most procedures ignore. In R the type actually changes what functions do, so getting it right up front prevents odd results later.

> **From the Crew Log:** classify the log the same way. `sex`, `nationality` and `occupation` are nominal. `hours_mission` and `total_number_of_missions` are ratio: zero means none, and 20 hours is twice 10. `year_of_mission` is interval: the year 0 isn't "no time". Knowing this now decides which tests you'll use later.

## Mission

Six participants' data are in the starter code.

1. `gender` is coded 1 = Woman, 2 = Man, 3 = Non-binary. Make `gender_f`, a factor with those labels.
2. `education` is highest degree. Make `education_f`, an **ordered** factor: HS < BA < MA < PhD.
3. `wellbeing` is a scale score (treat it as interval). Store its mean, ignoring the missing value, in `mean_wellbeing`.

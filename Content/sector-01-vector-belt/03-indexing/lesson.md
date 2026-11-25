# Picking Cargo

Square brackets pull values out of a vector by **position**. R counts from **1**, not 0:

```r
rt <- c(512, 468, 590, 433)
rt[1]          # first
#> [1] 512
rt[c(1, 3)]    # first and third
#> [1] 512 590
rt[2:4]        # second to fourth
#> [1] 468 590 433
rt[-1]         # everything EXCEPT the first
#> [1] 468 590 433
```

| You write | You get |
|---|---|
| `x[3]` | the 3rd value |
| `x[c(1, 4)]` | the 1st and 4th |
| `x[2:5]` | the 2nd to the 5th |
| `x[-2]` | everything but the 2nd |
| `x[length(x)]` | the last value, whatever the length |

Writing `x[length(x)]` instead of `x[6]` keeps working when the data change length. Code that survives new data is a habit worth building now.

## Mission

`reaction` holds six reaction times (ms) from one participant. Trial 1 was a **practice trial**.

1. Store the first trial in `first_trial`.
2. Store the last trial in `last_trial`, using `length()` rather than typing 6.
3. Store every trial except the practice trial in `real_trials`, using a negative index.
4. Store trials 2 to 5 in `middle_trials`.

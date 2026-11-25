# Broken Telescope

The observatory's plotting script has four faults. Two stop R with an error; two draw the *wrong* picture without any error at all, which is worse.

## The usual ggplot bugs

| Symptom | Cause |
|---|---|
| `could not find function "ggplot"` | `library(ggplot2)` is missing |
| `invalid argument to unary operator` | a line **starts** with `+`; it must **end** the line before |
| `` `mapping` must be created by `aes()` `` | layers joined with `\|>` instead of `+` |
| a legend saying "steelblue" and pinkish-red bars | a fixed colour put **inside** `aes()` |

The pipe and the plus look similar in a script but do different jobs: `|>` passes *data* into a function, `+` adds a *layer* to a plot.

## Mission

Fix the script so it draws both plots:

- `p_hist`: a histogram of `hours_mission` (30 bins), with every bar filled steel blue, and the axis labels as written;
- `p_sex`: a bar chart of missions by `sex`.

Keep the object names as they are.

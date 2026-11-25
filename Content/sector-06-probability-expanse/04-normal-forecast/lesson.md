# Normal Forecast

Six quick predictions. Work each out before you lock it in.

| Function | In | Out |
|---|---|---|
| `pnorm(q, mean, sd)` | a score | the proportion **below** it |
| `qnorm(p, mean, sd)` | a proportion | the score with that proportion below it |
| `rnorm(n, mean, sd)` | how many | *n* random draws from the curve |
| `dnorm(x, mean, sd)` | a score | the curve's **height** there (not a probability) |

With no `mean` and `sd`, all four use the **standard normal**: mean 0, SD 1, the scale of z-scores.

## Mission

Six predictions on the right.

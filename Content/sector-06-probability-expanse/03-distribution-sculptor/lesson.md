# Distribution Sculptor

Many scales in education and psychology are built so that scores follow a **normal distribution**: the bell curve. Two numbers fix its shape completely:

| Parameter | What it does to the curve |
|---|---|
| mean (μ) | where the peak sits |
| standard deviation (σ) | how spread out it is |

## Area is proportion

The total area under the curve is 1, so **the area over a range of scores is the proportion of scores in that range**. If 0.16 of the area lies below 85, then 16% of people score below 85. This is also a probability: pick one person at random, and there's a 0.16 chance they score below 85.

Areas don't depend on the scale, only on how many SDs from the mean you are. That's why the z-score matters:

**z = (score − mean) ÷ SD**

| Between… | Share of a normal curve |
|---|---|
| z = −1 and +1 | about 68% |
| z = −2 and +2 | about 95% (exactly 95% at ±1.96) |
| z = −3 and +3 | about 99.7% |

## The lab

Use the **Distribution Sculptor** on the right: move the mean and SD, choose what to shade, and drag the cutoff on the curve. The readout gives the shaded area, and under it the R call that computes the same number. Reach the three goals to open stage 2.

## Now do it in R

| Function | Gives you | Example |
|---|---|---|
| `pnorm(x, mean, sd)` | area **below** x | `pnorm(85, mean = 100, sd = 15)` → 0.159 |
| `pnorm(x, mean, sd, lower.tail = FALSE)` | area **above** x | same as `1 - pnorm(...)` |
| `qnorm(p, mean, sd)` | the score with proportion p below it | `qnorm(0.975, mean = 100, sd = 15)` → 129.4 |

`pnorm()` turns a score into a proportion; `qnorm()` turns a proportion back into a score. Leave out `mean` and `sd` and both use the standard normal (mean 0, SD 1), so `qnorm(0.975)` is the famous 1.96.

> **Coming from SPSS?** *Transform → Compute Variable* has the same two functions: `CDF.NORMAL(130, 100, 15)` is `pnorm(130, 100, 15)` and `IDF.NORMAL(0.975, 100, 15)` is `qnorm(0.975, 100, 15)`. *Descriptives → Save standardized values as variables* makes z-scores, which in R is `scale(x)`.

> **APA note:** numbers that can't exceed 1, such as probabilities and proportions, take no leading zero (*p* = .023); percentages use the % sign (2.3%). z-scores can exceed 1, so they keep the zero: *z* = 0.50, *z* = 2.00.

> **From the Crew Log:** ages at first flight in the log (approximate, from years) average about 40.3 years with an SD of about 5.3, a roughly bell-shaped spread with a slightly longer right tail, so a normal curve is a fair first model. Hours per mission are another matter: a median of 261 hours but a mean of 1,051. You'll sample from that lopsided distribution in the next lab.

## Mission

For test scores with mean **100** and SD **15**:

1. Store the proportion of scores **above 130** in `above_130`.
2. Store the **z-score** of 130 in `z_130`.
3. Store the proportion of scores **below 85** in `below_85`.
4. Store the two scores that cut off the **middle 95%** in `middle_95` (a vector of two numbers, from `qnorm()`).

# CI Rain

Welcome to Inference Station, where the questions change from *what does the sample show?* to *what can it tell us about everything we didn't measure?*

A point estimate (one sample mean) is almost never exactly right. A **confidence interval** gives a range of plausible values instead:

**mean ± t × SE**, where SE = SD / √*n* and *t* comes from the *t* distribution with *n* − 1 degrees of freedom (about 2 for a 95% interval).

## What "95% confidence" means

This is one of the most misunderstood ideas in statistics. It **doesn't** mean "there's a 95% chance μ is in *this* interval". Once you've computed it, μ either is in it or isn't. It means: **the method** captures μ in about 95% of samples. The lab lets you watch that happen.

## The lab

The population is a model of the Crew Log's ages at first flight: normal, with μ = 40 years and σ = 5. Each sample of *n* gives one interval; green ones capture μ (the gold line), red ones miss. Changing *n* or the confidence level starts a new set. Reach the four goals to open stage 2.

## Now do it in R

`t.test(x)$conf.int` gives the 95% confidence interval for the mean of `x`; `conf.level = 0.99` changes the level. To check the method, repeat it many times with `replicate()`. Code in braces `{ }` runs as one block, and the last line is what gets kept:

```r
replicate(3, {
  x <- rnorm(25, mean = 40, sd = 5)
  mean(x)
})
```

> **Coming from SPSS?** *Explore* and *One-Sample T Test* print a "95% Confidence Interval of the Difference". Same interval; here you can also see why it's built that way.

> **APA note:** report CIs in square brackets after the estimate: *M* = 40.3 years, 95% CI [38.2, 42.4].

## Mission

`ages` is a sample of 25 ages from the model population (the seed is set for you).

1. Store its 95% confidence interval in `ci95` and its 99% interval in `ci99`. Which is wider?
2. Repeat the method 1,000 times: draw 25 ages from N(40, 5), compute the 95% CI, and record whether it captures 40. Store the 1,000 TRUE/FALSE results in `captured`.
3. Store the proportion captured in `coverage`.

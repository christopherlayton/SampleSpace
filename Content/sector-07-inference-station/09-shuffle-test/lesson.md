# Shuffle Test

The sector's question, from your arrival briefing: **is the rise in women astronauts more than chance?**

## Hypotheses

Split the log's 564 first-time flyers by era: first flight **before 2000** or **2000 on**. Compare the proportion of women in each.

- **H₀:** era and sex are unrelated. Any gap between the eras is the kind of gap a random process would produce.
- **H₁:** the proportion of women differs between the eras (two-sided).

## A test you can see: shuffling

If H₀ were true, the era labels would carry no information about sex. So **shuffle them**: randomly reassign "before 2000" and "2000 on" to the same 564 people (keeping 392 and 172), and recompute the gap. Do that thousands of times and you have the **null distribution**: the gaps chance alone produces. The p-value is the share of shuffled gaps at least as large as the real one.

This is a **permutation test**. It needs no formula and no normality assumption, and it fits the Crew Log well: the log isn't a sample from a bigger population, so "random sampling" isn't the source of chance here. Shuffling asks directly whether the pattern could come from a random assignment of people to eras.

```r
x <- c("a", "a", "b", "b", "b")
sample(x)    # the same labels in a random order
```

> **Coming next:** the textbook test for two proportions is the chi-square test (Relationship Ring). With this many people, it and the shuffle test give very similar p-values.

> **APA note:** name the test and how many shuffles you ran: "A two-sided permutation test (5,000 permutations) gave *p* = …".

## Mission

`first`, `era` and `woman` are loaded for you, and the seed is set.

1. Store the observed gap, the proportion of women **2000 on** minus **before 2000**, in `observed`.
2. Shuffle `era` **5,000** times, recomputing the gap each time, and store the gaps in `shuffled`.
3. Store the two-sided p-value (the share of |shuffled| ≥ |observed|) in `p_shuffle`.
4. Store your decision at α = .05 in `decision`: either `"reject"` or `"fail to reject"`.
5. Draw a histogram of `shuffled` with a vertical line at `observed`: `abline(v = observed)`.

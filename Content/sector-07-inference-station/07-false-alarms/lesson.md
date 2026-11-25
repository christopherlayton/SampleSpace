# False Alarms

The Power Reactor's table of errors, measured by brute force.

| | H₀ true | H₀ false |
|---|---|---|
| **p < α** | Type I error (false alarm), rate α | correct: power |
| **p ≥ α** | correct | Type II error (miss), rate β |

You can't see these rates in a single study, because you never know which column you're in. In a simulation you do, because you built the world. Run thousands of studies where H₀ is true and count how often p < .05: that's the Type I error rate. Run thousands where there's a real effect and count again: that's power.

## One simulated study

```r
a <- rnorm(20)              # group 1: 20 people, mean 0, SD 1
b <- rnorm(20)              # group 2: same population, so H0 is true
t.test(a, b, var.equal = TRUE)$p.value
```

Give one group `mean = 0.5` and there's a real effect of half an SD: Cohen's d = 0.5.

## What to look for

- With H₀ true, about 5% of p-values fall below .05, **however many people you study**. α is the false-alarm rate you chose.
- With H₀ true, p-values are spread evenly between 0 and 1 (a flat histogram). A single p of .04 is not rare in a world with no effect; it happens 1 time in 25.
- With a real effect, the share below .05 is the power, and it should match `power.t.test()`.

## Mission

The seed is set for you.

1. Simulate **2,000** studies with **20 per group** and **no** real difference; store their p-values in `p_null`.
2. Store the share with p < .05 in `type1`.
3. Simulate 2,000 studies with 20 per group and a real effect of **d = 0.5**; store their p-values in `p_effect`.
4. Store the simulated power (share with p < .05) in `power_sim` and the miss rate in `type2`.
5. Store `power.t.test(n = 20, delta = 0.5)$power` in `power_exact`.
6. Draw a histogram of `p_null`.

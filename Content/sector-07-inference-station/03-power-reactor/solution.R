# Two-sample t-test, alpha = .05, two-sided; sd = 1 makes delta Cohen's d

# 1. Power with 20 per group, d = 0.5
power_20 <- power.t.test(n = 20, delta = 0.5, sd = 1)$power

# 2. n per group for 80% power at d = 0.5 (round up)
n_needed <- ceiling(power.t.test(power = 0.80, delta = 0.5, sd = 1)$n)

# 3. Smallest d with 80% power at 30 per group
d_30 <- power.t.test(n = 30, power = 0.80, sd = 1)$delta

# 4. n per group for 80% power at d = 0.2 (round up)
n_small <- ceiling(power.t.test(power = 0.80, delta = 0.2, sd = 1)$n)

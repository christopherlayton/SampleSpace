# 1. 1,000 ages from the model N(40, 5)
ages <- rnorm(1000, mean = 40, sd = 5)

# 2. Proportion above 50: simulated and exact
sim_over_50 <- mean(ages > 50)
exact_over_50 <- pnorm(50, mean = 40, sd = 5, lower.tail = FALSE)
c(simulated = sim_over_50, exact = exact_over_50)

# 3. Simulated mean and SD
sim_mean <- mean(ages)
sim_sd <- sd(ages)

# 4. Histogram
hist(ages)

# A sample of 25 ages from the model population (mu = 40, sigma = 5)
ages <- rnorm(25, mean = 40, sd = 5)

# 1. 95% and 99% confidence intervals
ci95 <- t.test(ages)$conf.int
ci99 <- t.test(ages, conf.level = 0.99)$conf.int

# 2. Does the method capture mu = 40? 1,000 times
captured <- replicate(1000, {
  x <- rnorm(25, mean = 40, sd = 5)
  ci <- t.test(x)$conf.int
  ci[1] <= 40 & 40 <= ci[2]
})

# 3. Proportion captured
coverage <- mean(captured)
coverage

# A sample of 25 ages from the model population (mu = 40, sigma = 5)
ages <- rnorm(25, mean = 40, sd = 5)

# 1. 95% and 99% confidence intervals
ci95 <- 
ci99 <- 

# 2. Does the method capture mu = 40? 1,000 times
captured <- replicate(1000, {
  x <- rnorm(25, mean = 40, sd = 5)
  
})

# 3. Proportion captured


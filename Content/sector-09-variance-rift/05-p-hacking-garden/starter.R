# Ten t-tests on pure noise: two groups of 20 from the same population
one_study <- function() {
  replicate(10, t.test(rnorm(20), rnorm(20), var.equal = TRUE)$p.value)
}

# 1. 1,000 studies
p_values <- 

# 2. Any significant outcome, per study, and the share of studies with one
any_hit <- 
rate <- 

# 3. Theory: 1 - (1 - alpha)^k
theory <- 

# 4. With Bonferroni: each p against 0.05 / 10
bonf_rate <- 

# 5. Adjust a paper's five p-values
reported <- c(0.004, 0.011, 0.020, 0.031, 0.240)
holm <- 
bonf <- 

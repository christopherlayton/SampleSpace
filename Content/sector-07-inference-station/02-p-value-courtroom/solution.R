# The evidence
diff <- 1.8
sd_pooled <- 6.5
n <- 19

# 1. Standard error, t and df
se <- sd_pooled * sqrt(2 / n)
t_obs <- diff / se
df <- 2 * n - 2

# 2. Two-sided and one-sided p-values
p_two <- 2 * pt(-abs(t_obs), df)
p_one <- pt(t_obs, df, lower.tail = FALSE)

# 3. 2,000 studies in a world where H0 is true
sim_t <- replicate(2000, {
  a <- rnorm(n, 0, sd_pooled)
  b <- rnorm(n, 0, sd_pooled)
  t.test(a, b, var.equal = TRUE)$statistic
})

# 4. How many were at least as extreme?
sim_p <- mean(abs(sim_t) >= abs(t_obs))
c(exact = p_two, simulated = sim_p)

# 1. 2,000 studies where H0 is true (20 per group)
p_null <- replicate(2000, {
  a <- rnorm(20)
  b <- rnorm(20)
  t.test(a, b, var.equal = TRUE)$p.value
})

# 2. False-alarm rate
type1 <- mean(p_null < 0.05)

# 3. 2,000 studies with a real effect, d = 0.5
p_effect <- replicate(2000, {
  a <- rnorm(20, mean = 0.5)
  b <- rnorm(20)
  t.test(a, b, var.equal = TRUE)$p.value
})

# 4. Simulated power and the miss rate
power_sim <- mean(p_effect < 0.05)
type2 <- 1 - power_sim

# 5. Power from the formula
power_exact <- power.t.test(n = 20, delta = 0.5)$power
c(type1 = type1, power_sim = power_sim, power_exact = power_exact)

# 6. Histogram of the null p-values
hist(p_null)

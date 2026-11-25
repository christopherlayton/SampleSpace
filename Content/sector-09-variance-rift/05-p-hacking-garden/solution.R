# Ten t-tests on pure noise: two groups of 20 from the same population
one_study <- function() {
  replicate(10, t.test(rnorm(20), rnorm(20), var.equal = TRUE)$p.value)
}

# 1. 1,000 studies
p_values <- replicate(1000, one_study())

# 2. Any significant outcome, per study, and the share of studies with one
any_hit <- apply(p_values < 0.05, 2, any)
rate <- mean(any_hit)

# 3. Theory: 1 - (1 - alpha)^k
theory <- 1 - 0.95^10

# 4. With Bonferroni: each p against 0.05 / 10
bonf_rate <- mean(apply(p_values < 0.05 / 10, 2, any))
c(rate = rate, theory = theory, bonf_rate = bonf_rate)

# 5. Adjust a paper's five p-values
reported <- c(0.004, 0.011, 0.020, 0.031, 0.240)
holm <- p.adjust(reported, method = "holm")
bonf <- p.adjust(reported, method = "bonferroni")
rbind(reported, holm, bonf)

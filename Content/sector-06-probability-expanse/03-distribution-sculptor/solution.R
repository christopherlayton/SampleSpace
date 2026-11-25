# Test scores: mean 100, SD 15

# 1. The proportion of scores above 130
above_130 <- pnorm(130, mean = 100, sd = 15, lower.tail = FALSE)

# 2. The z-score of 130
z_130 <- (130 - 100) / 15

# 3. The proportion of scores below 85
below_85 <- pnorm(85, mean = 100, sd = 15)

# 4. The two scores that cut off the middle 95%
middle_95 <- qnorm(c(0.025, 0.975), mean = 100, sd = 15)

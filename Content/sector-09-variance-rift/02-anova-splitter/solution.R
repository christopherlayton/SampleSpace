pd <- read.csv("pd_study.csv")
grand <- mean(pd$efficacy_t2)

# 1. Group means and sizes
means <- tapply(pd$efficacy_t2, pd$programme, mean)
n <- tapply(pd$efficacy_t2, pd$programme, length)

# 2. Sums of squares
ss_between <- sum(n * (means - grand)^2)
ss_within <- sum((pd$efficacy_t2 - means[pd$programme])^2)

# 3. F and p
f <- (ss_between / 2) / (ss_within / 57)
p <- pf(f, 2, 57, lower.tail = FALSE)

# 4. Eta squared
eta_sq <- ss_between / (ss_between + ss_within)
c(ss_between = ss_between, ss_within = ss_within, f = f, p = p, eta_sq = eta_sq)

# 5. Compare with aov()
summary(aov(efficacy_t2 ~ programme, data = pd))

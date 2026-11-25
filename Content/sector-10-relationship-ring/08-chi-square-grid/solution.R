counts <- matrix(c(28, 22,
                   20, 30), nrow = 2, byrow = TRUE,
                 dimnames = list(method = c("Lecture", "Active learning"),
                                 result = c("Passed", "Did not pass")))
counts

# 1. Pearson's chi-square (no correction) and the expected counts
pearson <- chisq.test(counts, correct = FALSE)
expected <- pearson$expected
pearson
expected

# 2. Pearson residuals
resid <- pearson$residuals
resid

# 3. Cramer's V by hand
v <- sqrt(unname(pearson$statistic) / (sum(counts) * (min(dim(counts)) - 1)))
v

# 4. R's default (Yates) and Fisher's exact test
yates <- chisq.test(counts)
fisher <- fisher.test(counts)
c(pearson = pearson$p.value, yates = yates$p.value, fisher = fisher$p.value)

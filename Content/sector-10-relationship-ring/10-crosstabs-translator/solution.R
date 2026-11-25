library(haven)
library(effectsize)
teach <- read_sav("teaching_study.sav")
teach$method <- as_factor(teach$method)

# 1. Passed: score of 70 or more
teach$passed <- factor(teach$score >= 70, levels = c(FALSE, TRUE), labels = c("Did not pass", "Passed"))

# 2. Crosstabulation
tab <- table(teach$method, teach$passed)
tab

# 3. Pearson, Continuity Correction and Fisher's Exact Test
pearson <- chisq.test(tab, correct = FALSE)
yates <- chisq.test(tab)
fisher <- fisher.test(tab)
pearson$expected
pearson
yates
fisher

# 4. Likelihood Ratio
g2 <- 2 * sum(tab * log(tab / pearson$expected))
g2

# 5. Phi and Cramer's V (unadjusted, as SPSS reports them)
phi_value <- phi(tab, adjust = FALSE)
v <- cramers_v(tab, adjust = FALSE)
phi_value
v

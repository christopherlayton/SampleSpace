# 1. Packages and the SPSS file
library(haven)
library(effectsize)
teach <- read_sav("teaching_study.sav")
teach$method <- as_factor(teach$method)

# 2. The two groups and the pooled SD
lecture <- teach$score[teach$method == "Lecture"]
active <- teach$score[teach$method == "Active learning"]
n1 <- length(lecture)
n2 <- length(active)
sd_pooled <- sqrt(((n1 - 1) * sd(lecture)^2 + (n2 - 1) * sd(active)^2) / (n1 + n2 - 2))

# 3. Cohen's d by hand (Lecture - Active learning)
d_hand <- (mean(lecture) - mean(active)) / sd_pooled
d_hand

# 4. The same with effectsize, and its CI
d_pkg <- cohens_d(score ~ method, data = teach)
d_pkg
d_ci <- c(d_pkg$CI_low, d_pkg$CI_high)

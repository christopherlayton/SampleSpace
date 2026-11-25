# 1. The survey and the pre-test scores
library(readr)
survey <- read_csv("wellbeing_survey.csv", show_col_types = FALSE)
x <- survey$anxiety_pre

# 2. Mean, standard error, critical t
m <- mean(x)
se <- sd(x) / sqrt(length(x))
t_crit <- qt(0.975, df = length(x) - 1)

# 3. The 95% confidence interval by hand
ci_by_hand <- c(m - t_crit * se, m + t_crit * se)
ci_by_hand

# 4. The same interval from t.test()
ci_r <- t.test(x)$conf.int
ci_r

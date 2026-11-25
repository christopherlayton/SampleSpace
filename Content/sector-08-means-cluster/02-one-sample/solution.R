# 1. The survey
library(readr)
survey <- read_csv("wellbeing_survey.csv", show_col_types = FALSE)

# 2. One-sample t-test against the norm of 28
res <- t.test(survey$anxiety_pre, mu = 28)
res

# 3. t, df, p and the CI
t_val <- unname(res$statistic)
df_val <- unname(res$parameter)
p_val <- res$p.value
ci <- res$conf.int

# 4. Mean difference from the norm
mean_diff <- unname(res$estimate) - 28

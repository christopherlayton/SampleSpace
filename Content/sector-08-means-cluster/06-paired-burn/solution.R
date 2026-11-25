# 1. The survey
library(readr)
survey <- read_csv("wellbeing_survey.csv", show_col_types = FALSE)

# 2. Paired t-test, pre vs post
paired <- t.test(survey$anxiety_pre, survey$anxiety_post, paired = TRUE)
paired

# 3. The same test on the differences
diffs <- survey$anxiety_pre - survey$anxiety_post
on_diffs <- t.test(diffs)

# 4. Complete pairs, mean difference and d_z
n_pairs <- sum(!is.na(diffs))
mean_diff <- mean(diffs, na.rm = TRUE)
d_z <- mean_diff / sd(diffs, na.rm = TRUE)

# 1. The survey
library(readr)
survey <- read_csv("wellbeing_survey.csv", show_col_types = FALSE)

# 2. Welch's and Student's t-tests of post-test anxiety by group
welch <- t.test(anxiety_post ~ group, data = survey)
student <- t.test(anxiety_post ~ group, data = survey, var.equal = TRUE)
welch
student

# 3. Welch's df and p
welch_df <- unname(welch$parameter)
p_welch <- welch$p.value

# 4. Control minus Mindfulness
diff_means <- unname(welch$estimate[1] - welch$estimate[2])

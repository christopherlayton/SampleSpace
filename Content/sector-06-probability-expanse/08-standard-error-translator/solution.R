# 1. The survey
library(readr)
survey <- read_csv("wellbeing_survey.csv", show_col_types = FALSE)

# 2. A function for the standard error of the mean (ignoring NAs)
se_mean <- function(x) {
  sd(x, na.rm = TRUE) / sqrt(sum(!is.na(x)))
}

# 3. The two standard errors
se_pre <- se_mean(survey$anxiety_pre)
se_post <- se_mean(survey$anxiety_post)
c(pre = se_pre, post = se_post)

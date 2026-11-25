# 1. The survey and the pre-test scores
library(readr)
survey <- read_csv("wellbeing_survey.csv", show_col_types = FALSE)
x <- survey$anxiety_pre

# 2. Mean, standard error, critical t
m <- 
se <- 
t_crit <- 

# 3. The 95% confidence interval by hand
ci_by_hand <- 

# 4. The same interval from t.test()
ci_r <- 

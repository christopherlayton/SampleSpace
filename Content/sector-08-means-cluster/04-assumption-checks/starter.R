# 1. Packages and the survey
library(readr)
library(car)
survey <- read_csv("wellbeing_survey.csv", show_col_types = FALSE)

# 2. Normality in each group
control <- survey$anxiety_post[survey$group == "Control"]
mindful <- 
sw_control <- 
sw_mindful <- 

# 3. Levene's test: car's default and SPSS's version
levene_median <- 
levene_mean <- 

# 4. p-value of SPSS's version
levene_p <- 

# 5. Q-Q plot of control


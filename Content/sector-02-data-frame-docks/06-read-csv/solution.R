# 1. Load readr and import the file
library(readr)
survey <- read_csv("wellbeing_survey.csv")

# 2. How many students?
n_students <- nrow(survey)

# 3. How many in each group?
group_counts <- table(survey$group)

# 4. Mean post-test anxiety
mean_post <- mean(survey$anxiety_post, na.rm = TRUE)

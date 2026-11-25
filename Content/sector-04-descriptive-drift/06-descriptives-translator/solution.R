# 1. Packages and the survey
library(readr)
library(psych)
survey <- read_csv("wellbeing_survey.csv")

# 2. SPSS-style descriptives
vars <- c("age", "anxiety_pre", "anxiety_post")
desc <- describe(survey[, vars], type = 2)
desc

# 3. Two numbers from the table
skew_post <- desc["anxiety_post", "skew"]
kurt_age <- desc["age", "kurtosis"]

# 4. Valid N (listwise)
n_listwise <- sum(complete.cases(survey[, vars]))

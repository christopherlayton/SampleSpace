# 1. Packages and the survey
library(readr)
library(psych)
survey <- read_csv("wellbeing_survey.csv")

# 2. Describe four variables at once
desc <- describe(survey[, c("age", "anxiety_pre", "anxiety_post", "satisfaction")])
desc

# 3. Median satisfaction, from desc
sat_median <- desc["satisfaction", "median"]

# 4. Which variable is most skewed?
most_skewed <- rownames(desc)[which.max(abs(desc$skew))]

library(readr)

# 1. Import
survey <- read_csv("wellbeing_survey.csv", show_col_types = FALSE)

# 2. group as a factor, Control first
survey$group <- factor(survey$group, levels = c("Control", "Mindfulness"))

# 3. Missing values per column
missing_per_column <- colSums(is.na(survey))

# 4. Students with complete data
n_complete <- sum(complete.cases(survey))

# 5. Change score (post - pre)
survey$change <- survey$anxiety_post - survey$anxiety_pre

# 6. Mean change
mean_change <- mean(survey$change, na.rm = TRUE)

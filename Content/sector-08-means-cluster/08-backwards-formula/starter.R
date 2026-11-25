# Wellbeing study: group difference and change over the term.
library(readr)
library(effectsize)
survey <- read_csv("wellbeing_survey.csv", show_col_types = FALSE)

# Did post-test anxiety differ between the groups?
groups_test <- t.test(group ~ anxiety_post, data = survey)
groups_test

# Levene's test, SPSS-style
levene <- leveneTest(anxiety_post ~ factor(group), data = survey, center = mean)

# Did anxiety drop from pre-test to post-test?
change_test <- t.test(survey$anxiety_pre, survey$anxiety_post)
change_test

# Effect size for the group difference
d <- cohens_d(anxiety_post ~ group)
d

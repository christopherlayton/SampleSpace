# 1. Packages and the survey
library(readr)
library(car)
survey <- read_csv("wellbeing_survey.csv", show_col_types = FALSE)

# 2. Normality in each group
control <- survey$anxiety_post[survey$group == "Control"]
mindful <- survey$anxiety_post[survey$group == "Mindfulness"]
sw_control <- shapiro.test(control)$p.value
sw_mindful <- shapiro.test(mindful)$p.value

# 3. Levene's test: car's default and SPSS's version
levene_median <- leveneTest(anxiety_post ~ factor(group), data = survey)
levene_mean <- leveneTest(anxiety_post ~ factor(group), data = survey, center = mean)
levene_mean

# 4. p-value of SPSS's version
levene_p <- levene_mean$"Pr(>F)"[1]

# 5. Q-Q plot of control
qqnorm(control)
qqline(control)

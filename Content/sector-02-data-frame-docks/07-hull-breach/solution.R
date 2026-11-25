# Mean post-test anxiety in each group of the mindfulness study.
# It worked on the old computer. Now it doesn't.
library(readr)
survey <- read_csv("wellbeing_survey.csv")

mindful <- survey[survey$group == "Mindfulness", ]
control <- survey[survey$group == "Control", ]

mean_mindful <- mean(mindful$anxiety_post, na.rm = TRUE)
mean_control <- mean(control$anxiety_post, na.rm = TRUE)

mean_mindful
mean_control

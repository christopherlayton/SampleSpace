# Mean post-test anxiety in each group of the mindfulness study.
# It worked on the old computer. Now it doesn't.

survey <- read_csv("wellbeing_survey.csv")

mindful <- survey[survey$group = "Mindfulness", ]
control <- survey[survey$group == "control", ]

mean_mindful <- mean(mindful$Anxiety_post, na.rm = TRUE)
mean_control <- mean(control$anxiety_post)

mean_mindful
mean_control

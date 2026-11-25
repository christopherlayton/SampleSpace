# 1. Packages and the survey
library(readr)
library(dplyr)
library(ggplot2)
survey <- read_csv("wellbeing_survey.csv")

# 2. Summarise first
post_summary <- survey |>
  group_by(group) |>
  summarise(n = sum(!is.na(anxiety_post)),
            mean_post = mean(anxiety_post, na.rm = TRUE),
            se = sd(anxiety_post, na.rm = TRUE) / sqrt(n))
post_summary

# 3. Then plot the summary
p_means <- ggplot(post_summary, aes(x = group, y = mean_post)) +
  geom_col() +
  geom_errorbar(aes(ymin = mean_post - se, ymax = mean_post + se), width = 0.2)
p_means

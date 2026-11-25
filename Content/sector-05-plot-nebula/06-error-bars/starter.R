# 1. Packages and the survey
library(readr)
library(dplyr)
library(ggplot2)
survey <- read_csv("wellbeing_survey.csv")

# 2. Summarise first
post_summary <- survey |>
  group_by(group) |>
  summarise()

# 3. Then plot the summary


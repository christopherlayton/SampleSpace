library(readr)
library(dplyr)
library(car)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)
people <- astronauts |>
  group_by(number) |>
  summarise(military_civilian = first(military_civilian), mean_hours = mean(hours_mission))
leveneTest(mean_hours ~ factor(military_civilian), data = people, center = mean)
t.test(mean_hours ~ military_civilian, data = people)
cohens_d(mean_hours ~ military_civilian, data = people)

library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)
people <- astronauts |>
  group_by(number) |>
  summarise(missions = n(), eva_hours = sum(eva_hrs_mission))
cor.test(people$missions, people$eva_hours)
cor.test(people$missions, people$eva_hours, method = "spearman", exact = FALSE)
model <- lm(eva_hours ~ missions, data = people)
summary(model)
predict(model, data.frame(missions = 3))

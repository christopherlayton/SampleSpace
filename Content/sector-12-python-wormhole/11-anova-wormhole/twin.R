library(readr)
library(dplyr)
library(car)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)
first <- astronauts |>
  filter(mission_number == 1) |>
  mutate(age = year_of_mission - year_of_birth, decade = factor(floor(year_of_mission / 10) * 10))
fit <- aov(age ~ decade, data = first)
summary(fit)
eta_squared(fit)
TukeyHSD(fit)
leveneTest(age ~ decade, data = first, center = mean)
oneway.test(age ~ decade, data = first)

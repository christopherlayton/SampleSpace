library(readr)
library(dplyr)
library(ggplot2)
log <- read_csv("astronauts.csv", show_col_types = FALSE)
ggplot(log, aes(x = hours_mission)) + geom_histogram(bins = 40) + labs(x = "Hours per mission")
first <- log |>
  filter(mission_number == 1) |>
  mutate(age = year_of_mission - year_of_birth, decade = factor(floor(year_of_mission / 10) * 10))
ggplot(first, aes(x = decade, y = age)) + geom_boxplot() + labs(y = "Age at first flight")

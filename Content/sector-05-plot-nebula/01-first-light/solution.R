# 1. Packages and the crew log
library(readr)
library(dplyr)
library(ggplot2)
astronauts <- read_csv("astronauts.csv")

# 2. Histogram of mission length
p_hours <- ggplot(astronauts, aes(x = hours_mission)) +
  geom_histogram(bins = 40)
p_hours

# 3. First flights, with age
first_flights <- astronauts |>
  filter(mission_number == 1) |>
  mutate(age = year_of_mission - year_of_birth)

# 4. Histogram of age at first flight
p_age <- ggplot(first_flights, aes(x = age)) +
  geom_histogram(binwidth = 2)
p_age

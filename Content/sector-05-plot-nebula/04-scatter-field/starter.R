# 1. Packages, the crew log, and ages
library(readr)
library(dplyr)
library(ggplot2)
astronauts <- read_csv("astronauts.csv")
missions <- astronauts |>
  mutate(age_at_mission = year_of_mission - year_of_birth)

# 2. Age against year


# 3. Coloured by sex, with trend lines


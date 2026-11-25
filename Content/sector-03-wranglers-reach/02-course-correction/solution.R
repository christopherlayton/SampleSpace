# 1. Packages and the crew log
library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv")

# 2. Two new columns
missions <- astronauts |>
  mutate(days = hours_mission / 24,
         age_at_mission = year_of_mission - year_of_birth)

# 3. The five longest missions
longest <- missions |>
  arrange(desc(days)) |>
  select(name, year_of_mission, days) |>
  slice_head(n = 5)

# 4. Oldest age at a mission
oldest_age <- max(missions$age_at_mission)

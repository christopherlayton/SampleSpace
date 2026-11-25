# 1. Packages and the crew log
library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv")

# 2. Missions and median length, by sex
by_sex <- astronauts |>
  group_by(sex) |>
  summarise(missions = n(),
            median_hours = median(hours_mission))

# 3. Astronauts per nationality (one row per person first!)
nation_counts <- astronauts |>
  filter(mission_number == 1) |>
  count(nationality, sort = TRUE)

# 4. Which nationality has the most?
top_nation <- nation_counts$nationality[1]

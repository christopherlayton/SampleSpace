# 1. Packages and the crew log
library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv")

# 2. Missions from 2010 on, four columns
recent <- astronauts |>
  filter(year_of_mission >= 2010) |>
  select(name, nationality, year_of_mission, hours_mission)

# 3. How many?
n_recent <- nrow(recent)

# 4. Women's missions longer than 4,000 hours
long_women <- astronauts |>
  filter(sex == "female", hours_mission > 4000)

# 1. Packages, the crew log, and the typo fixes
library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv")

clean <- astronauts |>
  mutate(nationality = case_when(
    nationality == "Hungry" ~ "Hungary",
    nationality == "Malysia" ~ "Malaysia",
    nationality == "Netherland" ~ "Netherlands",
    .default = nationality
  ))

# 2. One row per astronaut (SPSS: AGGREGATE /BREAK=number)
roster <- clean |>
  group_by(number) |>
  summarise(name = first(name),
            sex = first(sex),
            nationality = first(nationality),
            missions = n(),
            total_hours = sum(hours_mission),
            eva_hours = sum(eva_hrs_mission))

# 3. Spacewalkers (SPSS: COMPUTE spacewalker = eva_hours > 0)
n_spacewalkers <- sum(roster$eva_hours > 0)

# 4. Percentage of astronauts
pct_spacewalkers <- round(100 * n_spacewalkers / nrow(roster), 1)

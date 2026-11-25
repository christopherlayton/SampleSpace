# 1. Packages, the crew log, and the typo fixes
library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv")

clean <- astronauts |>
  mutate()

# 2. One row per astronaut (SPSS: AGGREGATE /BREAK=number)
roster <- clean |>
  group_by(number) |>
  summarise()

# 3. Spacewalkers (SPSS: COMPUTE spacewalker = eva_hours > 0)


# 4. Percentage of astronauts


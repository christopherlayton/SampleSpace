# 1. Packages and the crew log
library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv")

# Look before you fix: every spelling of each category
sort(unique(astronauts$nationality))
sort(unique(astronauts$occupation))

# 2. Fix the nationality typos and the capitals
clean <- astronauts |>
  mutate()

# 3. How many occupation spellings, before and after?


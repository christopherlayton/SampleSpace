# 1. Packages and the crew log
library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv")

# Look before you fix: every spelling of each category
sort(unique(astronauts$nationality))
sort(unique(astronauts$occupation))

# 2. Fix the nationality typos and the capitals
clean <- astronauts |>
  mutate(
    nationality = case_when(
      nationality == "Hungry" ~ "Hungary",
      nationality == "Malysia" ~ "Malaysia",
      nationality == "Netherland" ~ "Netherlands",
      .default = nationality
    ),
    occupation = tolower(occupation)
  )

# 3. How many occupation spellings, before and after?
n_jobs_raw <- n_distinct(astronauts$occupation)
n_jobs_clean <- n_distinct(clean$occupation)

# Missing-data report for the morale survey.
library(readr)
library(dplyr)
morale <- read_csv("crew_morale.csv")

# Missing values in each column
missing_per_column <- colSums(is.na(morale))
missing_per_column

# Participants who reported their sleep
n_sleep <- morale |> filter(!is.na(sleep_hours)) |> nrow()

# Mean sleep in each programme
sleep_by_programme <- morale |>
  group_by(programme) |>
  summarise(mean_sleep = mean(sleep_hours, na.rm = TRUE))

# Participants who answered all six morale items
n_all_items <- morale |> filter(if_all(m1:m6, ~ !is.na(.x))) |> nrow()

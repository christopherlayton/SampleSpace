# Missing-data report for the morale survey.
library(readr)
library(dpylr)
morale <- read_csv("crew_morale.csv")

# Missing values in each column
missing_per_column <- colSums(is.na(morale))
missing_per_column

# Participants who reported their sleep
n_sleep <- morale |> filter(sleep_hours != NA) |> nrow()

# Mean sleep in each programme
sleep_by_programme <- morale |>
  group_by(programme) |>
  summarise(mean_sleep = mean(sleep_hours))

# Participants who answered all six morale items
n_all_items <- nrow(na.omit(morale))

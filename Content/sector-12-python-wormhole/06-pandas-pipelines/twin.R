library(readr)
library(dplyr)
log <- read_csv("astronauts.csv", show_col_types = FALSE)
first <- log |>
  filter(mission_number == 1) |>
  mutate(age = year_of_mission - year_of_birth)
count(first, nationality, sort = TRUE) |> head(3)
first |> group_by(sex) |> summarise(count = n(), mean = mean(age))
first |> arrange(desc(age)) |> slice_head(n = 3) |> select(name, age)

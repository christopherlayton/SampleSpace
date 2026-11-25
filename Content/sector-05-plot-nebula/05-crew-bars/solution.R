# 1. Packages, the crew log, first flights by decade
library(readr)
library(dplyr)
library(ggplot2)
astronauts <- read_csv("astronauts.csv")
first_flights <- astronauts |>
  filter(mission_number == 1) |>
  mutate(decade = floor(year_of_mission / 10) * 10)

# 2. Counts per decade, filled by sex
p_count <- ggplot(first_flights, aes(x = factor(decade), fill = sex)) +
  geom_bar()
p_count

# 3. Proportions per decade
p_share <- ggplot(first_flights, aes(x = factor(decade), fill = sex)) +
  geom_bar(position = "fill")
p_share

# 4. First-time flyers and women per decade
women_by_decade <- first_flights |>
  group_by(decade) |>
  summarise(flyers = n(),
            women = sum(sex == "female"))
women_by_decade

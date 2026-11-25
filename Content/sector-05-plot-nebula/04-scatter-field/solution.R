# 1. Packages, the crew log, and ages
library(readr)
library(dplyr)
library(ggplot2)
astronauts <- read_csv("astronauts.csv")
missions <- astronauts |>
  mutate(age_at_mission = year_of_mission - year_of_birth)

# 2. Age against year
p_scatter <- ggplot(missions, aes(x = year_of_mission, y = age_at_mission)) +
  geom_point(alpha = 0.3)
p_scatter

# 3. Coloured by sex, with trend lines
p_trend <- ggplot(missions, aes(x = year_of_mission, y = age_at_mission, colour = sex)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm")
p_trend

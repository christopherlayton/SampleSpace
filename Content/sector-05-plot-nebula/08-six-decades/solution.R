# 1. Packages, the crew log, and decades
library(readr)
library(dplyr)
library(ggplot2)
astronauts <- read_csv("astronauts.csv")
missions <- astronauts |>
  mutate(decade = floor(year_of_mission / 10) * 10)

# 2. Median mission length per decade
decade_medians <- missions |>
  group_by(decade) |>
  summarise(median_hours = median(hours_mission))
decade_medians

# 3. The figure
p_final <- ggplot(decade_medians, aes(x = decade, y = median_hours)) +
  geom_line() +
  geom_point() +
  labs(x = "Decade", y = "Median mission length (hours)") +
  theme_classic()
p_final

# 4. Save it
ggsave("six_decades.png", p_final, width = 6, height = 4)

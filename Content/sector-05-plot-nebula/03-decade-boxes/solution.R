# 1. Packages, the crew log, and decades
library(readr)
library(dplyr)
library(ggplot2)
astronauts <- read_csv("astronauts.csv")
missions <- astronauts |>
  mutate(decade = floor(year_of_mission / 10) * 10)

# 2. Boxplots by decade
p_box <- ggplot(missions, aes(x = factor(decade), y = hours_mission)) +
  geom_boxplot()
p_box

# 3. The same on a log scale
p_log <- p_box + scale_y_log10()
p_log

# 4. Median by decade
decade_medians <- missions |>
  group_by(decade) |>
  summarise(median_hours = median(hours_mission))
decade_medians

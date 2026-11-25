# Two quick looks at the crew log.
library(readr)
library(ggplot2)
astronauts <- read_csv("astronauts.csv")

# Mission lengths, in steel blue
p_hist <- ggplot(astronauts, aes(x = hours_mission)) +
  geom_histogram(bins = 30, fill = "steelblue") +
  labs(x = "Mission length (hours)", y = "Missions")
p_hist

# Missions by sex
p_sex <- ggplot(astronauts, aes(x = sex)) +
  geom_bar()
p_sex

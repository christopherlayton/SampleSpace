# Two quick looks at the crew log.
library(readr)
astronauts <- read_csv("astronauts.csv")

# Mission lengths, in steel blue
p_hist <- ggplot(astronauts, aes(x = hours_mission, fill = "steelblue")) +
  geom_histogram(bins = 30)
  + labs(x = "Mission length (hours)", y = "Missions")
p_hist

# Missions by sex
p_sex <- ggplot(astronauts, aes(x = sex)) |>
  geom_bar()
p_sex

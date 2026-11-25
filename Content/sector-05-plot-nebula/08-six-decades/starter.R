# 1. Packages, the crew log, and decades
library(readr)
library(dplyr)
library(ggplot2)
astronauts <- read_csv("astronauts.csv")
missions <- astronauts |>
  mutate(decade = floor(year_of_mission / 10) * 10)

# 2. Median mission length per decade
decade_medians <- 

# 3. The figure
p_final <- 

# 4. Save it


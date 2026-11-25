# 1. Packages and the crew log
library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv")

# 2. Missions and median length, by sex
by_sex <- astronauts |>
  

# 3. Astronauts per nationality (one row per person first!)
nation_counts <- astronauts |>
  

# 4. Which nationality has the most?


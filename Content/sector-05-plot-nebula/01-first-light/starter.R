# 1. Packages and the crew log
library(readr)
library(dplyr)
library(ggplot2)
astronauts <- read_csv("astronauts.csv")

# 2. Histogram of mission length
p_hours <- ggplot(astronauts, aes(x = hours_mission))


# 3. First flights, with age
first_flights <- 

# 4. Histogram of age at first flight


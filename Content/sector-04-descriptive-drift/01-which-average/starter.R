# 1. The crew log
library(readr)
astronauts <- read_csv("astronauts.csv")

# 2. Mean and median mission length (hours)
mean_hours <- 
median_hours <- 

# 3. The most common number of missions per astronaut
first_flights <- astronauts[astronauts$mission_number == 1, ]
counts <- table(first_flights$total_number_of_missions)
mode_missions <- 

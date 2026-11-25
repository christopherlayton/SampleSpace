library(readr)

# 1. Import the crew log
astronauts <- read_csv("astronauts.csv")

# 2. How many rows (missions)?
n_missions <- nrow(astronauts)

# 3. How many different astronauts?
n_astronauts <- length(unique(astronauts$number))

# 4. One row per astronaut: their first mission
first_flights <- astronauts[astronauts$mission_number == 1, ]

# 5. Sex, counted per person
sex_counts <- table(first_flights$sex)

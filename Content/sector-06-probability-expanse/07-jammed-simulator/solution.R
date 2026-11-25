# Sampling distribution of mean age at first flight, for random crews of 10.
library(readr)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)
first <- astronauts[astronauts$mission_number == 1, ]
age <- first$year_of_mission - first$year_of_birth

# One big resample of 1,000 ages
big_draw <- sample(age, size = 1000, replace = TRUE)

# The mean ages of 2,000 random crews of 10
crew_means <- replicate(2000, {
  mean(sample(age, size = 10, replace = TRUE))
})

# Standard error: simulated, and from the formula
se_sim <- sd(crew_means)
se_formula <- sd(age) / sqrt(10)
c(simulated = se_sim, formula = se_formula)

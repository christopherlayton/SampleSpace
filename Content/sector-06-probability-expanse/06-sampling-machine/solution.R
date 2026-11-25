library(readr)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)
hours <- astronauts$hours_mission

# 1. One random crew: 30 missions drawn with replacement
one_crew <- sample(hours, size = 30, replace = TRUE)

# 2. The means of 1,000 random crews of 30
crew_means <- replicate(1000, mean(sample(hours, size = 30, replace = TRUE)))

# 3. The standard error: simulated, and from the formula
se_sim <- sd(crew_means)
se_formula <- sd(hours) / sqrt(30)

# 4. A histogram of crew_means
hist(crew_means)

# 1. The crew log
library(readr)
astronauts <- read_csv("astronauts.csv")
hours <- astronauts$hours_mission

# 2. z-scores
z_hours <- (hours - mean(hours)) / sd(hours)

# 3. More than 3 SDs from the mean
n_extreme <- sum(abs(z_hours) > 3)

# 4. The largest z
max_z <- max(z_hours)
astronauts$name[which.max(z_hours)]

# 5. Proportion below the mean
prop_below <- mean(z_hours < 0)

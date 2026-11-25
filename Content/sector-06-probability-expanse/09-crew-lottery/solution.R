library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)
first <- astronauts |> filter(mission_number == 1)

# 1. Women among first-time flyers
women <- first$sex == "female"
p_log <- mean(women)

# 2. Proportions of women in 2,000 random crews of 50, and of 200
props_50 <- replicate(2000, mean(sample(women, size = 50, replace = TRUE)))
props_200 <- replicate(2000, mean(sample(women, size = 200, replace = TRUE)))

# 3. Simulated standard errors and their ratio
se_50 <- sd(props_50)
se_200 <- sd(props_200)
se_ratio <- se_50 / se_200
se_ratio

# 4. The formula SE for crews of 50
se_50_formula <- sqrt(p_log * (1 - p_log) / 50)

# 5. Histogram of props_50
hist(props_50)

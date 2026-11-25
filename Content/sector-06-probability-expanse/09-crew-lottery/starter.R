library(readr)
library(dplyr)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)
first <- astronauts |> filter(mission_number == 1)

# 1. Women among first-time flyers
women <- 
p_log <- 

# 2. Proportions of women in 2,000 random crews of 50, and of 200
props_50 <- 
props_200 <- 

# 3. Simulated standard errors and their ratio


# 4. The formula SE for crews of 50


# 5. Histogram of props_50


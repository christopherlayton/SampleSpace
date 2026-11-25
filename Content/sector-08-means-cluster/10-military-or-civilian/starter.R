library(readr)
library(dplyr)
library(car)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)

# 1. One row per astronaut: status and mean hours per mission
people <- astronauts |>
  group_by(number) |>
  summarise()

# 2. Describe each group: n, mean, sd, median of mean_hours
group_stats <- 

# 3. Levene (SPSS-style), Welch's t-test and Cohen's d
levene <- 
welch <- 
d <- 

# 4. Decision at alpha = .05
decision <- 

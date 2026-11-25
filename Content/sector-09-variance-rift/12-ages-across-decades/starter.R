library(readr)
library(dplyr)
library(car)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)

# 1. First missions, with age and decade
first <- astronauts |>
  filter() |>
  mutate()

# 2. n, mean and sd of age per decade
decade_stats <- 

# 3. Levene's test (SPSS-style)
levene <- 

# 4. Classic and Welch's ANOVA
classic <- 
welch <- 

# 5. Effect size and Games-Howell post hoc tests
eta <- 
games <- 

# 6. Which test fits, and your decision at alpha = .05
test_used <- 
decision <- 

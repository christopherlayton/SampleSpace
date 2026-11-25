library(readr)
library(dplyr)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)

# 1. First missions, with era
first <- astronauts |>
  filter(mission_number == 1) |>
  mutate(era = )

# 2. Counts and row proportions
crew_table <- 
row_pct <- 

# 3. Chi-square test without the correction; are the expected counts big enough?
test <- 
expected_ok <- 

# 4. Adjusted residuals
adj_resid <- 

# 5. Cramer's V, unadjusted (as SPSS reports it)
v <- 

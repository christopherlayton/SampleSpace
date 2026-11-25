library(readr)
library(dplyr)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)

# 1. First missions, with era
first <- astronauts |>
  filter(mission_number == 1) |>
  mutate(era = factor(ifelse(year_of_mission >= 2000, "2000 on", "before 2000"),
                      levels = c("before 2000", "2000 on")))

# 2. Counts and row proportions
crew_table <- table(first$era, first$sex)
row_pct <- prop.table(crew_table, margin = 1)
crew_table
round(row_pct * 100, 1)

# 3. Chi-square test without the correction; are the expected counts big enough?
test <- chisq.test(crew_table, correct = FALSE)
expected_ok <- all(test$expected >= 5)
test
test$expected

# 4. Adjusted residuals
adj_resid <- test$stdres
adj_resid

# 5. Cramer's V, unadjusted (as SPSS reports it)
v <- cramers_v(crew_table, adjust = FALSE)
v

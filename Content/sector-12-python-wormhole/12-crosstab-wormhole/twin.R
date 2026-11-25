library(readr)
library(dplyr)
library(effectsize)
astronauts <- read_csv("astronauts.csv", show_col_types = FALSE)
first <- astronauts |>
  filter(mission_number == 1) |>
  mutate(era = factor(ifelse(year_of_mission >= 2000, "2000 on", "before 2000"),
                      levels = c("before 2000", "2000 on")))
crew_table <- table(first$era, first$sex)
crew_table
round(prop.table(crew_table, margin = 1) * 100, 1)
test <- chisq.test(crew_table, correct = FALSE)
test
test$expected
cramers_v(crew_table, adjust = FALSE)

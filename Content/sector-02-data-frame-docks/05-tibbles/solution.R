# 1. Load the tibble package
library(tibble)

# 2. Convert study and glimpse it
study_tbl <- as_tibble(study)
glimpse(study_tbl)

# 3. A new tibble with a calculated column
pilot <- tibble(
  id = 1:4,
  score = c(38, 45, 29, 41),
  score_pct = score / 50 * 100
)

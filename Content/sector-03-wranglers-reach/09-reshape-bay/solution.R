# 1. Packages and the survey
library(readr)
library(dplyr)
library(tidyr)
morale <- read_csv("crew_morale.csv")

# 2. Items to long format
morale_long <- morale |>
  pivot_longer(m1:m6, names_to = "item", values_to = "rating")

# 3. One row per item
item_summary <- morale_long |>
  group_by(item) |>
  summarise(mean_rating = mean(rating, na.rm = TRUE),
            n_missing = sum(is.na(rating)))

# 4. Lowest mean
lowest_item <- item_summary$item[which.min(item_summary$mean_rating)]

# 5. Back to wide
morale_wide <- morale_long |>
  pivot_wider(names_from = item, values_from = rating)

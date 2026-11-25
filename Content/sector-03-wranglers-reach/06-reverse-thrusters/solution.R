# 1. Packages and the survey
library(readr)
library(dplyr)
morale <- read_csv("crew_morale.csv")

# 2. A negative item correlates negatively
r_before <- cor(morale$m1, morale$m2, use = "complete.obs")

# 3. Reverse-score m2 and m5 (scale 1-5)
morale <- morale |>
  mutate(m2_r = 6 - m2,
         m5_r = 6 - m5)

# 4. After reversing
r_after <- cor(morale$m1, morale$m2_r, use = "complete.obs")

# 5. Composite score and its mean
morale <- morale |>
  mutate(morale_score = rowMeans(pick(m1, m2_r, m3, m4, m5_r, m6), na.rm = TRUE))
mean_morale <- mean(morale$morale_score)

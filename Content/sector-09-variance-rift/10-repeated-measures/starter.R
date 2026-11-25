library(afex)
library(dplyr)
library(tidyr)
pd <- read.csv("pd_study.csv")

# 1. Wide to long: one row per teacher per time
long <- pd |>
  select(id, starts_with("efficacy")) |>
  pivot_longer()

# 2. Mean efficacy at each time
time_means <- 

# 3. Repeated-measures ANOVA
rm <- 

# 4. Mauchly's test of sphericity: its p-value
mauchly_p <- 

# 5. Paired follow-up comparisons, Holm-corrected
follow_up <- 

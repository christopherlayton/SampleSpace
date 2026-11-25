library(afex)
library(dplyr)
library(tidyr)
pd <- read.csv("pd_study.csv")

# 1. Wide to long: one row per teacher per time
long <- pd |>
  select(id, starts_with("efficacy")) |>
  pivot_longer(starts_with("efficacy"), names_to = "time", values_to = "efficacy")

# 2. Mean efficacy at each time
time_means <- long |>
  group_by(time) |>
  summarise(mean = mean(efficacy))
time_means

# 3. Repeated-measures ANOVA
rm <- aov_ez(id = "id", dv = "efficacy", data = long, within = "time")
rm
summary(rm)

# 4. Mauchly's test of sphericity: its p-value
mauchly_p <- summary(rm)$sphericity.tests[, "p-value"]
mauchly_p

# 5. Paired follow-up comparisons, Holm-corrected
follow_up <- pairwise.t.test(long$efficacy, long$time, paired = TRUE, p.adjust.method = "holm")
follow_up
